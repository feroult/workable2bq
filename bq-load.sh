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

VALID_ACTIVITIES="activities AS
(
  select a.id, 
         candidate.id as candidate,  
         action as stage,
         j.title as job,
         DATE_TRUNC(EXTRACT(DATE FROM a.created_at), DAY) as date,
         a.created_at as datetime
     from workable.activities a
left join workable.jobs j on a.job_shortcode = j.shortcode 
  where action in ('applied', 'referral', 'uploaded', 'sourced', 'shortlisted', 'phone-screen', 'interview', 'offer', 'offer-sent','hired', 'offer-accepted', 'disqualified')
    and a.created_at >= TIMESTAMP '$FIRST_DATE'
)"

create_activities_flow() {

    echo "Creating activities_flow..."

    bq query \
        --destination_table workable.activities_flow \
        --replace \
        --use_legacy_sql=false \
"WITH 
$VALID_ACTIVITIES,
date_range AS
(
  SELECT
        DATE_SUB(DATE_TRUNC(CURRENT_DATE(), DAY), INTERVAL date DAY) date
      FROM
        UNNEST(GENERATE_ARRAY(0, (SELECT MAX(DATE_DIFF(CURRENT_DATE(), date, DAY)) from activities))) AS date
),
max_dates AS (
  select candidate, stage, min(date) date from
    (
      select a1.candidate candidate, a1.stage stage, a2.date date
        from activities a1
      left outer join activities a2 on a1.candidate = a2.candidate and a1.stage <> a2.stage and a1.datetime < a2.datetime
    )
  group by candidate, stage
),
cross_actions AS 
(
  SELECT d.date, a.id, a.stage, a.candidate, a.job FROM activities a
    FULL OUTER JOIN date_range d ON TRUE
   WHERE d.date >= a.date
),
actions_flow AS 
(
   select * from cross_actions c
   where 
     ( date < (select date from max_dates m where candidate = c.candidate and m.stage = c.stage) 
            OR (select date from max_dates m where candidate = c.candidate and m.stage = c.stage) IS NULL)
)

select *, date_trunc(date, WEEK(SUNDAY)) week from actions_flow"

}

create_activities_daily() {

    echo "Creating activities_daily..."

    bq query \
        --destination_table workable.activities_daily \
        --replace \
        --use_legacy_sql=false \
"WITH 
$VALID_ACTIVITIES

select *, date_trunc(date, WEEK(SUNDAY)) week from activities"

}


# load jobs
# load activities
create_activities_flow
create_activities_daily
