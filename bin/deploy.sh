#!/bin/sh -xe

PROJECT_ID="workable2bq"

gcloud run deploy workable2bq \
    --image gcr.io/${PROJECT_ID}/workable2bq \
    --region us-central1 \
    --platform managed \
    --memory 512Mi \
    --set-env-vars "WORKABLE_TOKEN=$WORKABLE_TOKEN" \
    --set-env-vars "WORKABLE_DOMAIN=$WORKABLE_DOMAIN" \
    --set-env-vars "BUCKET_NAME=$BUCKET_NAME" \
    --timeout=15m \
    -q

