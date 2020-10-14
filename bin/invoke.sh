#!/bin/sh -x

curl -H \
    "Authorization: Bearer $(gcloud auth print-identity-token)" \
    https://workable2bq-exesre2qma-uc.a.run.app/views