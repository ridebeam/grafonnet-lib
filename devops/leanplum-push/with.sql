with
  'rideQRScreenLoaded' as step1,
  'startTripBegin' as step2,
  'startTripCompleted' as step3,
  'endTripBegin' as step4,
  'endTripCompleted' as step5,
src as (
  select 
    *,
    coalesce(parseDateTimeBestEffortOrNull(_client_event_time), event_time) as client_event_time
  from 
    $table  
  where $timeFilter
  and event_name in (step1, step2, step3, step4, step5)
),

events as (
  select
    user_id,
    event_name,
    success,
    if (client_event_time <= event_time, client_event_time, event_time) as event_time
  from src
  where $timeFilterByColumn(client_event_time)
),

step1 as (
  select 's1' as step, * from events where event_name = step1
),

step2 as (
  select 's2' as step, s2.*
  from events s2
  join step1 s1 on s1.user_id=s2.user_id
  where s2.event_name = step2
  and s1.event_time <= s2.event_time and date_diff('minute', s1.event_time, s2.event_time) <= 30
),

step3 as (
  select 's3' as step, s3.*
  from events s3
  join step2 s2 on s2.user_id=s3.user_id
  where s3.event_name = step3 and s3.success='true'
  and s2.event_time <= s3.event_time and date_diff('minute', s2.event_time, s3.event_time) <= 30
),

step4 as (
  select 's4' as step, s4.*
  from events s4
  join step3 s3 on s3.user_id=s4.user_id
  where s4.event_name = step4
  and s3.event_time <= s4.event_time and date_diff('minute', s3.event_time, s4.event_time) <= 30
),

step5 as (
  select 's5' as step, s5.*
  from events s5
  join step4 s4 on s4.user_id=s5.user_id
  where s5.event_name = step5 and s5.success='true'
  and s4.event_time <= s5.event_time and date_diff('minute', s4.event_time, s5.event_time) <= 30
),

combined as (
  select * from step1
  union all
  select * from step2
  union all
  select * from step3
  union all
  select * from step4
  union all
  select * from step5
),

result as (
  select
    count(distinct case when step='s1' then user_id end) as s1,
    count(distinct case when step='s2' then user_id end) as s2,
    count(distinct case when step='s3' then user_id end) as s3,
    count(distinct case when step='s4' then user_id end) as s4,
    count(distinct case when step='s5' then user_id end) as s5
  from combined
)

select
  --s1,
  100*s1/s1 as rideQRScreenLoaded,
  --s2,
  100*s2/s1 as startTripBegin,
  --s3,
  100*s3/s2 as startTripCompleted,
  --s4,
  100*s4/s3 as endTripBegin,
  --s4,
  100*s5/s4 as endTripCompleted
from result
limit 3
