#!/bin/bash

load_candidates_details() {
  echo "Loading candidates details..."
  bq load --replace \
    --autodetect \
    --source_format=NEWLINE_DELIMITED_JSON \
   workable.candidates_details gs://$BUCKET_NAME/candidates/*.json /app/schema-candidates_details.json
  echo "---------"
}

load_candidates_resumes() {
  echo "Loading candidates resumes..."
  bq load --replace \
    --autodetect \
    --source_format=NEWLINE_DELIMITED_JSON \
   workable.candidates_resumes gs://$BUCKET_NAME/candidates_resumes/*.json
  echo "---------"
}


create_candidates_view() {
    echo "Creating candidates view..."

    bq query \
        --destination_table views.candidates \
        --replace \
        --use_legacy_sql=false \
"CREATE TEMP FUNCTION IS_IN(arr1 ANY TYPE, arr2 ANY TYPE) AS (
  (SELECT COUNT(1) FROM UNNEST(arr1) el JOIN UNNEST(arr2) el USING(el)) > 0);

WITH valid_candidates AS
(
  SELECT c.*,
    CASE 
      WHEN IS_IN(tags, ['referrals']) THEN true
      ELSE false
    END referral,
    CASE 
      WHEN IS_IN(tags, ['jr', 'junior', 'jr1', 'jr1_inicio', 'jr2', 'junior_2', 'junior1', 'junior2', 'junor']) THEN 'JR'
      WHEN IS_IN(tags, ['plano', 'pleno', 'pleno_1', 'pleno_2', 'pleno1', 'pleno2', 'pl', 'pl1', 'pl2', 'pl1_incio', 'pl2_inicio']) THEN 'PL'
      WHEN IS_IN(tags, ['senior', 'senior_1', 'senior_2', 'senior1', 'senior2', 'sr', 'sr1', 'sr1_inicio', 'sr1_ressalvas', 'sr2', 'sr3']) THEN 'SR'
      ELSE NULL
    END seniority,
   CASE
      WHEN c.disqualified = true THEN 'disqualified'
      WHEN c.hired_at IS NOT NULL THEN 'hired'
      ELSE 'open'
    END AS status,    
    r.resume    
    FROM workable.candidates_details c
    JOIN workable.jobs j ON c.job.shortcode = j.shortcode
    JOIN workable.candidates c0 ON c0.id = c.id
    LEFT OUTER JOIN workable.candidates_resumes r ON r.id = c.id
     AND j.department = 'DEXTRA'

)

SELECT * FROM valid_candidates"

}

load_candidates_details
load_candidates_resumes
create_candidates_view