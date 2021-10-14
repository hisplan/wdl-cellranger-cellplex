version 1.0

task Multi {

    input {
        String runName
        String gexFastqName
        String muxFastqName
        Array[File] gexFastqFiles
        Array[File] muxFastqFiles
        Float minAssignmentConfidence
        File cmoReference
        File sampleCmoMap
        String reference

        # docker-related
        String dockerRegistry
    }

    parameter_meta {
        cmoReference: { help: "https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/multi#cmoreference" }
        sampleCmoMap: { help: "Refer to the [samples] section in https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/multi#cellranger-multi" }
    }

    String cellRangerVersion = "6.0.2"
    String dockerImage = dockerRegistry + "/cromwell-cellranger:" + cellRangerVersion
    Float inputSize = size(gexFastqFiles, "GiB") + size(muxFastqFiles, "GiB") + 20
    Int cores = 16
    Int memoryGB = 128

    # ~{runName} : the top-level output directory containing pipeline metadata
    # ~{runName}/outs/ : contains the final pipeline output files.
    String outDir = runName + "/outs"
    String outDirMulti = outDir + "/multi"
    String outDirPerSample = outDir + "/per_sample_outs"

    command <<<
        set -euo pipefail

        export MRO_DISK_SPACE_CHECK=disable

        # download reference
        curl -L --silent -o reference.tgz ~{reference}
        mkdir -p reference
        tar xvzf reference.tgz -C reference --strip-components=1
        chmod -R +r reference
        rm -rf reference.tgz

        # aggregate all the GEX fastq files into a single directory
        mkdir -p fastq-gex
        mv -v ~{sep=' ' gexFastqFiles} ./fastq-gex/

        # aggregate all the MUX fastq files into a single directory
        mkdir -p fastq-mux
        mv -v ~{sep=' ' muxFastqFiles} ./fastq-mux/

        # generate multi.config.csv
        # reference and fastq folder must be an absolute path
        cat > multi.config.csv<< EOF
[gene-expression]
reference,$(pwd)/reference
min-assignment-confidence,~{minAssignmentConfidence}

[feature]
reference,~{cmoReference}

[libraries]
fastq_id,fastqs,feature_types,lanes
~{gexFastqName},$(pwd)/fastq-gex/,Gene Expression,any
~{muxFastqName},$(pwd)/fastq-mux/,Multiplexing Capture,any

[samples]
$(cat ~{sampleCmoMap})
EOF

        cat multi.config.csv

        # run the multi pipeline
        cellranger multi \
            --id=~{runName} \
            --csv=multi.config.csv \
            --localcores=~{cores - 1} \
            --localmem=~{memoryGB - 5}

        # targz the per_sample_output folder
        if [ $? -eq 0 ]
        then
            # ├── count
            # │   ├── analysis
            # │   │   ├── clustering
            # │   │   ├── diffexp
            # │   │   ├── pca
            # │   │   ├── tsne
            # │   │   └── umap
            # │   ├── cloupe.cloupe
            # │   ├── feature_reference.csv
            # │   ├── sample_alignments.bam
            # │   ├── sample_alignments.bam.bai
            # │   ├── sample_barcodes.csv
            # │   ├── sample_feature_bc_matrix
            # │   │   ├── barcodes.tsv.gz
            # │   │   ├── features.tsv.gz
            # │   │   └── matrix.mtx.gz
            # │   ├── sample_feature_bc_matrix.h5
            # │   └── sample_molecule_info.h5
            # ├── metrics_summary.csv
            # └── web_summary.html

            # gather metrics_summary.csv & web_summary.html from each sample and make a tarball
            find ~{outDirPerSample} -maxdepth 2 -name "*.html" -o -name "*.csv" | tar -cf per-sample-outs-summary.tar --files-from -

            # each sample outs will be made into a tarball
            ls -1 ~{outDirPerSample} | xargs -I {} tar cf {}.outs.tar ~{outDirPerSample}/{}/
        fi

    >>>

    output {

        # └─ multi
        #    ├── count
        #    │   ├── feature_reference.csv
        #    │   ├── raw_cloupe.cloupe
        #    │   ├── raw_feature_bc_matrix
        #    │   │   ├── barcodes.tsv.gz
        #    │   │   ├── features.tsv.gz
        #    │   │   └── matrix.mtx.gz
        #    │   ├── raw_feature_bc_matrix.h5
        #    │   ├── raw_molecule_info.h5
        #    │   ├── unassigned_alignments.bam
        #    │   └── unassigned_alignments.bam.bai
        #    └── multiplexing_analysis
        #        ├── assignment_confidence_table.csv
        #        ├── cells_per_tag.json
        #        ├── tag_calls_per_cell.csv
        #        └── tag_calls_summary.csv

        File multiConfig = "multi.config.csv"

        File featureReference = outDirMulti + "/count/feature_reference.csv"
        File? cloupe = outDirMulti + "/count/raw_cloupe.cloupe"
        Array[File] rawFeatureBCMatrix = glob(outDirMulti + "/count/raw_feature_bc_matrix/*")
        File rawFeatureBCMatrixH5 = outDirMulti + "/count/raw_feature_bc_matrix.h5"
        File rawMoleculeInfoH5 = outDirMulti + "/count/raw_molecule_info.h5"
        File unassignedBam = outDirMulti + "/count/unassigned_alignments.bam"
        File unassignedBai = outDirMulti + "/count/unassigned_alignments.bam.bai"

        File assignmentConfidenceTable = outDirMulti + "/multiplexing_analysis/assignment_confidence_table.csv"
        File cellsPerTag = outDirMulti + "/multiplexing_analysis/cells_per_tag.json"
        File tagCallesPerCell = outDirMulti + "/multiplexing_analysis/tag_calls_per_cell.csv"
        File tagCallsSummary = outDirMulti + "/multiplexing_analysis/tag_calls_summary.csv"

        File perSampleOutsSummary = "per-sample-outs-summary.tar"
        Array[File] perSampleOuts = glob("*.outs.tar")

        File pipestanceMeta = runName + "/" + runName + ".mri.tgz"
    }

    runtime {
        docker: dockerImage
        disks: "local-disk " + ceil(2 * (if inputSize < 1 then 100 else inputSize )) + " HDD"
        cpu: cores
        memory: memoryGB + " GB"
    }
}
