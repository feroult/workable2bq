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

create_views_scheduler() {
  gcloud scheduler jobs delete ${JOB_ID}
  gcloud scheduler jobs create http ${JOB_ID} \
    --http-method=GET \
    --schedule="0 8-20 * * *" \
    --uri=${URI}/views \
    --oidc-service-account-email=${CLIENT_SERVICE_ACCOUNT_EMAIL}
}

create_details_scheduler() {
  gcloud scheduler jobs delete ${JOB_ID}
  gcloud scheduler jobs create http ${JOB_ID} \
    --http-method=GET \
    --schedule="20,30,40 8-20 * * *" \
    --uri=${URI}/details \
    --oidc-service-account-email=${CLIENT_SERVICE_ACCOUNT_EMAIL}
}

# create_service_account
create_views_scheduler
create_details_scheduler