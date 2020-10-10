#!/bin/sh -xe

PROJECT_ID="workable2bq"

gcloud builds submit --tag gcr.io/${PROJECT_ID}/workable2bq
