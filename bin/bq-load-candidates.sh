#!/bin/bash

load_candidates_details() {
  echo "Loading candidates details..."
  bq load --replace \
    --autodetect \
    --source_format=NEWLINE_DELIMITED_JSON \
   workable.candidates_details gs://$BUCKET_NAME/candidates/*.json /app/schema-candidates_details.json
  echo "---------"
}

# workable.candidates_details gs://$BUCKET_NAME/candidates/*.json

load_candidates_details