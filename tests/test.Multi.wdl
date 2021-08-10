version 1.0

import "modules/Multi.wdl" as module

workflow Multi {

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

    call module.Multi {
        input:
            runName = runName,
            gexFastqName = gexFastqName,
            muxFastqName = muxFastqName,
            gexFastqFiles = gexFastqFiles,
            muxFastqFiles = muxFastqFiles,
            minAssignmentConfidence = minAssignmentConfidence,
            cmoReference = cmoReference,
            sampleCmoMap = sampleCmoMap,
            reference = reference,
            dockerRegistry = dockerRegistry,
    }

    output {
        File multiConfig = Multi.multiConfig

        File featureReference = Multi.featureReference
        File? cloupe = Multi.cloupe
        Array[File] rawFeatureBCMatrix = Multi.rawFeatureBCMatrix
        File rawFeatureBCMatrixH5 = Multi.rawFeatureBCMatrixH5
        File rawMoleculeInfoH5 = Multi.rawMoleculeInfoH5
        File unassignedBam = Multi.unassignedBam
        File unassignedBai = Multi.unassignedBai

        File assignmentConfidenceTable = Multi.assignmentConfidenceTable
        File cellsPerTag = Multi.cellsPerTag
        File tagCallesPerCell = Multi.tagCallesPerCell
        File tagCallsSummary = Multi.tagCallsSummary

        File perSampleOuts = Multi.perSampleOuts

        File pipestanceMeta = Multi.pipestanceMeta
    }
}