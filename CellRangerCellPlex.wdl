version 1.0

import "modules/Multi.wdl" as Multi

workflow CellRangerCellPlex {

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

        Boolean includeIntrons
        Int? expectCells = 3000

        # docker-related
        String dockerRegistry
    }

    call Multi.Multi {
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
            includeIntrons = includeIntrons,
            expectCells = expectCells,
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

        File perSampleOutsSummary = Multi.perSampleOutsSummary
        Array[File] perSampleOuts = Multi.perSampleOuts

        File pipestanceMeta = Multi.pipestanceMeta
    }
}
