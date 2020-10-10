#!/bin/sh -x

PROJECT_ID="workable2bq"
JOB_ID="export"
URI="https://workable2bq-exesre2qma-uc.a.run.app"
CLIENT_SERVICE_ACCOUNT_EMAIL="${JOB_ID}@${PROJECT_ID}.iam.gserviceaccount.com "

create_service_account() {
  gcloud iam service-accounts create ${JOB_ID}

  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${CLIENT_SERVICE_ACCOUNT_EMAIL} \
    --role roles/run.invoker
}

create_scheduler() {
  gcloud scheduler jobs delete ${JOB_ID}
  gcloud scheduler jobs create http ${JOB_ID} \
    --http-method=GET \
    --schedule="5 8-20 * * *" \
    --uri=${URI} \
    --oidc-service-account-email=${CLIENT_SERVICE_ACCOUNT_EMAIL}
}

# create_service_account
create_scheduler