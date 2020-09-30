#!/bin/bash

load() {
    echo "Loading $1..."
    bq load --replace \
        --autodetect \
        --source_format=NEWLINE_DELIMITED_JSON \
        workable.$1 /exports/$1.json
    echo "---------"
}

load jobs
load activities
