#!/usr/bin/env bash

java -jar ~/Applications/womtool.jar \
    validate \
    CellRangerCellPlex.wdl \
    --inputs ./configs/CellRangerCellPlex.inputs.json
