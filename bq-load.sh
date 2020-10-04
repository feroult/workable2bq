#!/bin/bash

FIRST_DATE="2020-08-01"

# shortlisted, phone-screen, interview, offer, offer-sent,hired, offer-accepted

load() {
    echo "Loading $1..."
    bq load --replace \
        --autodetect \
        --source_format=NEWLINE_DELIMITED_JSON \
        workable.$1 /exports/$1.json
    echo "---------"
}

create_stages_flow() {

  echo "Creating stages_flow..."

  bq query \
    --destination_table views.stages_flow \
    --replace \
    --use_legacy_sql=false \
"WITH valid_candidates AS
(
  SELECT c.* 
    FROM workable.candidates c
    JOIN workable.jobs j ON c.job.shortcode = j.shortcode
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
  SELECT STRUCT(c.id, name, c.domain) AS candidate, job, 'Disqualified' as stage, TIMESTAMP_ADD(updated_at, interval 1 HOUR) AS created_at
    FROM valid_candidates c
   WHERE disqualified = true
),
last_activities AS
(
  SELECT STRUCT(c.id, c.name, c.domain) AS candidate, job, stage, 
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
 SELECT STRUCT(candidate.id, candidate.name, c.domain) AS candidate, STRUCT(j.title, j.shortcode) AS job, stage_name AS stage, a.created_at created_at
   FROM workable.activities a   
   JOIN workable.jobs j ON a.job_shortcode = j.shortcode   
   JOIN valid_candidates c ON c.id = a.candidate.id   
  WHERE stage_name IS NOT NULL
),
activities AS
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
last_stages AS
(
  SELECT a.* 
    FROM activities a
    JOIN 
    (
      SELECT candidate.id, MAX(created_at) created_at
        FROM activities
       GROUP BY candidate.id    
    ) m
    ON a.candidate.id = m.id AND a.created_at = m.created_at
)

SELECT * FROM activities"

}

create_stages_cumulative_flow() {

    echo "Creating stages_cumulative_flow..."

    bq query \
        --destination_table views.stages_cumulative_flow \
        --replace \
        --use_legacy_sql=false \
"WITH date_range AS
(
  SELECT
        DATE_SUB(DATE_TRUNC(CURRENT_DATE(), DAY), INTERVAL date DAY) date
      FROM
        UNNEST(GENERATE_ARRAY(0, (SELECT MAX(DATE_DIFF(CURRENT_DATE(), date, DAY)) from views.stages_flow))) AS date
),
max_dates AS (
  select candidate_id, stage, min(date) date from
    (
      select a1.candidate.id candidate_id, a1.stage stage, a2.date date
        from views.stages_flow a1
      left outer join views.stages_flow a2 on a1.candidate.id = a2.candidate.id and a1.stage <> a2.stage and a1.date < a2.date
    )
  group by candidate_id, stage
),
cross_stages AS 
(
  SELECT candidate, job, stage, d.date FROM views.stages_flow a
    FULL OUTER JOIN date_range d ON TRUE
   WHERE d.date >= a.date
),
stages_cumulative_flow AS 
(
   select c.* from cross_stages c
   where 
     ( date < (select date from max_dates m where candidate_id = c.candidate.id and m.stage = c.stage) 
            OR (select date from max_dates m where candidate_id = c.candidate.id and m.stage = c.stage) IS NULL)
)

SELECT * FROM stages_cumulative_flow"

}

create_stages_daily() {

    echo "Creating stages_daily..."

    bq query \
        --destination_table views.stages_daily \
        --replace \
        --use_legacy_sql=false \
"SELECT *, DATE_TRUNC(date, WEEK(SUNDAY)) week FROM views.stages_flow"

}

# load jobs
# load activities
# load candidates

# views

# create_stages_flow
# create_stages_cumulative_flow
create_stages_daily

# create_activities_flow
# create_activities_daily
