#!/bin/bash

FIRST_DATE="2020-08-01"

# shortlisted, phone-screen, interview, offer, offer-sent,hired, offer-accepted

load() {
    echo "Loading $1..."
    bq load --replace \
        --autodetect \
        --source_format=NEWLINE_DELIMITED_JSON \
        workable.$1 /export_views/$1.json
    echo "---------"
}

create_flow() {

  echo "Creating flow..."

  bq query \
    --destination_table views.flow \
    --replace \
    --use_legacy_sql=false \
"WITH valid_candidates AS
(
  SELECT * FROM views.candidates
),
last_stage_activities AS
(
  SELECT a.* 
    FROM workable.activities a
    JOIN 
    (
      SELECT candidate.id, MAX(created_at) created_at
        FROM workable.activities
       WHERE stage_name IS NOT NULL
       GROUP BY candidate.id

    ) m
    ON a.candidate.id = m.id AND a.created_at = m.created_at
),
moved AS
(
  SELECT candidate.id, max(created_at) created_at
    FROM workable.activities
   WHERE action = 'moved'  
   GROUP BY candidate.id
),
disqualified AS
(
  SELECT STRUCT(c.id, name, c.domain, c.referral, c.seniority, c.status, c.interview, c.make_contact) AS candidate, job, 'Disqualified' as stage, TIMESTAMP_ADD(updated_at, interval 1 HOUR) AS created_at
    FROM valid_candidates c
   WHERE disqualified = true
),
last_activities AS
(
  SELECT STRUCT(c.id, c.name, c.domain, c.referral, c.seniority, c.status, c.interview, c.make_contact) AS candidate, job, stage, 
         CASE 
            WHEN a.id IS NOT NULL THEN m.created_at
            ELSE c.created_at
         END created_at
   FROM valid_candidates c
   LEFT OUTER JOIN last_stage_activities a 
     ON a.candidate.id = c.id 
   LEFT OUTER JOIN moved m ON m.id = c.id
   WHERE a.id IS NULL OR c.stage <> a.stage_name
),
valid_activities AS
(
 SELECT STRUCT(candidate.id, candidate.name, c.domain, c.referral, c.seniority, c.status, c.interview, c.make_contact) AS candidate, 
        STRUCT(j.title, j.shortcode) AS job, stage_name AS stage, a.created_at created_at
   FROM workable.activities a   
   JOIN workable.jobs j ON a.job_shortcode = j.shortcode   
   JOIN valid_candidates c ON c.id = a.candidate.id   
  WHERE stage_name IS NOT NULL
    AND j.department = 'DEXTRA'
),
activities_union AS
(
  SELECT *, DATE_TRUNC(EXTRACT(DATE FROM created_at), DAY) as date FROM
  (
    SELECT * FROM last_activities
    UNION ALL
    SELECT * FROM valid_activities  
    UNION ALL
    SELECT * FROM disqualified
  )
),
activities_uuid AS (
SELECT 
  GENERATE_UUID() uuid,
  *,
  CASE
     WHEN stage = 'Sourced' THEN 1
     WHEN stage = 'Applied' THEN 2
     WHEN stage = 'Fazer Contato' THEN 3
     WHEN stage = 'Mapea' THEN 4
     WHEN stage = 'Av.Técnica' THEN 5
     WHEN stage = 'Entrevista DEXTRA' THEN 6
     WHEN stage = 'Proposta' THEN 7
     WHEN stage = 'Aprovado/Contratado' THEN 8
     WHEN stage = 'Disqualified' THEN 9
     ELSE 10
  END stage_order
  FROM activities_union
),
activities AS
(
  SELECT 
    uuid,
    STRUCT(
       a.candidate.id, 
       a.candidate.name,
       a.candidate.domain,
       a.candidate.referral, 
       a.candidate.seniority,
       c.sourced,     
       a.candidate.status,
       a.candidate.interview,
       a.candidate.make_contact,
       c.created_at,
       c.updated_at,
       TIMESTAMP(c.hired_at) AS hired_at
    ) AS candidate,
    a.job,
    a.stage,
    a.created_at,
    a.date,
    DATE_TRUNC(a.date, WEEK(MONDAY)) week,
    DATE_TRUNC(a.date, MONTH) month,
    a.stage_order
    FROM activities_uuid a
    LEFT JOIN workable.candidates c ON a.candidate.id = c.id
)

SELECT * FROM activities"

}

create_max_dates() {

    echo "Creating max_dates..."

    bq query \
        --destination_table views.max_dates \
        --replace \
        --use_legacy_sql=false \
"SELECT *,
        LEAD(date) OVER (PARTITION BY candidate.id ORDER BY created_at ASC) AS max_date
  FROM views.flow
ORDER BY created_at"

}

create_cumulative_flow() {

    echo "Creating cumulative_flow..."

    bq query \
        --destination_table views.cumulative_flow \
        --replace \
        --use_legacy_sql=false \
"WITH date_range AS
(
  SELECT
        DATE_SUB(DATE_TRUNC(CURRENT_DATE(), DAY), INTERVAL date DAY) date
      FROM
        UNNEST(GENERATE_ARRAY(0, (SELECT MAX(DATE_DIFF(CURRENT_DATE(), date, DAY)) from views.flow))) AS date
),
cross_stages AS 
(
  SELECT uuid, candidate, job, stage, stage_order, d.date FROM views.flow a
    FULL OUTER JOIN date_range d ON TRUE
   WHERE d.date >= a.date
),
cumulative_flow AS 
(
  SELECT c.* 
    FROM cross_stages c
   WHERE 
      ( date < (SELECT max_date FROM views.max_dates m WHERE uuid = c.uuid) 
            OR (SELECT max_date FROM views.max_dates m WHERE uuid = c.uuid) IS NULL)
)

SELECT * FROM cumulative_flow"

}

load jobs
load activities
load candidates

# views

create_flow
create_max_dates
create_cumulative_flow
