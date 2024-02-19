local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local startTripQuery() =
  |||
    with src as (
        select 
            *,
            SUBSTRING(appVersion, 6, position(appVersion, '-', 6) - position(appVersion, '-', 1)-1) as app_version,
            coalesce(parseDateTimeBestEffortOrZero(_client_event_time), event_time) as client_event_time
        from 
            $table  
        where $timeFilter
        and event_name in ('startTripBegin', 'startTripCompleted')
        and app_version in ($app_version)
    ),

    events as (
        select
            user_id,
            app_version,
            event_name,
            success,
            if (client_event_time <= event_time, client_event_time, event_time) as event_time
        from src
        where $timeFilterByColumn(client_event_time)
    ),

    step1 as (
        select 
            *,
            any(event_time) OVER (PARTITION BY user_id ORDER BY event_time ASC ROWS
                        BETWEEN 1 FOLLOWING AND 1 FOLLOWING) AS next_event_time
        from events
        where event_name = 'startTripBegin'
    ),

    step2 as (
        select 
            *
        from events
        where event_name = 'startTripCompleted'
        and success = '$success'
    ),

    join_table as (
        select
            s1.user_id as user_id,
            s1.event_time as step1_event_time,
            s1.app_version as app_version,
            MIN(s2.event_time) as step2_event_time
        from step1 as s1
        inner join step2 as s2
        on s1.user_id = s2.user_id
        where s1.event_time <= s2.event_time
        and s2.event_time < if(s1.next_event_time = toDateTime('1970-01-01'), toDateTime('2040-12-31'), s1.next_event_time)
        and s1.app_version = s2.app_version
        group by user_id, step1_event_time, app_version
    )
    
    select
        app_version as app_version,
        AVG(date_diff('second', step1_event_time, step2_event_time)) as avg_second_used
    from join_table
    group by app_version
    having date_diff('second', step1_event_time, step2_event_time) <= 90
  |||
;

local startTripDistributionQuery() =
  |||
    with src as (
        select 
            *,
            SUBSTRING(appVersion, 6, position(appVersion, '-', 6) - position(appVersion, '-', 1)-1) as app_version,
            coalesce(parseDateTimeBestEffortOrZero(_client_event_time), event_time) as client_event_time
        from 
            $table  
        where $timeFilter
        and event_name in ('startTripBegin', 'startTripCompleted')
        and app_version in ($app_version)
    ),

    events as (
        select
            user_id,
            app_version,
            event_name,
            success,
            if (client_event_time <= event_time, client_event_time, event_time) as event_time
        from src
        where $timeFilterByColumn(client_event_time)
    ),

    step1 as (
        select 
            *,
            any(event_time) OVER (PARTITION BY user_id ORDER BY event_time ASC ROWS
                        BETWEEN 1 FOLLOWING AND 1 FOLLOWING) AS next_event_time
        from events
        where event_name = 'startTripBegin'
    ),

    step2 as (
        select 
            *
        from events
        where event_name = 'startTripCompleted'
        and success = '$success'
    ),

    join_table as (
        select
            s1.user_id as user_id,
            s1.event_time as step1_event_time,
            s1.app_version as app_version,
            MIN(s2.event_time) as step2_event_time
        from step1 as s1
        inner join step2 as s2
        on s1.user_id = s2.user_id
        where s1.event_time <= s2.event_time
        and s2.event_time < if(s1.next_event_time = toDateTime('1970-01-01'), toDateTime('2040-12-31'), s1.next_event_time)
        and s1.app_version = s2.app_version
        group by user_id, step1_event_time, app_version
    ),

    second_diff as (
        select
            app_version,
            user_id as user_id,
            date_diff('second', step1_event_time, step2_event_time) as second_used
        from join_table
        where date_diff('second', step1_event_time, step2_event_time) <= 90
    )

    select
      app_version,
      multiIf(
        second_used <= 5, '0-5', 
        second_used <= 10,'6-10',
        second_used <= 15,'11-15',
        second_used <= 20,'16-20',
        second_used <= 30,'21-30',
        second_used <= 40,'31-40',
        second_used <= 50,'41-50',
        second_used <= 60,'51-60',
        second_used <= 70,'61-70',
        second_used <= 80,'71-80',
        second_used <= 90,'81-90',
        '>90'
      ) as time_bucket,
      count(user_id) as count
    from second_diff
    group by app_version, time_bucket
    order by app_version, time_bucket asc
  |||
;

local startTripTarget() =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='event_time',
    query=startTripQuery(),
    table='app_events',
  ) {
    format: 'table',
  }
;

local startTripDistributionTarget() =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='event_time',
    query=startTripDistributionQuery(),
    table='app_events',
  ) {
    format: 'table',
  }
;

grafana.dashboard.new(
  'Start Trip Time to Convert',
  uid='start_trip_time_to_convert',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addTemplate(
  template.new(
    name='app_version',
    label='App Version',
    datasource='Altinity plugin for ClickHouse',
    query='SELECT distinct appVersion FROM jwebb.app_events WHERE event_time >= toDateTime(today()-7) limit 50',
    regex='/(\\d+\\.\\d+\\.\\d+)/',
    multi=true,
    includeAll=true,
  )
)

.addTemplate(
  template.custom(
    name='success',
    label='Start Trip Completed success',
    query='true,false',
    current='true',
  )
)

.addRows([
  row.new('Start Trip Time').addPanels([
    panel.halfRow(
      panel.new(title='Start Trip')
      .addTargets([startTripTarget()])
    ) { type: 'table' },
    panel.halfRow(
      panel.new(title='Start Trip Distribution')
      .addTargets([startTripDistributionTarget()])
    ) { type: 'table' },
  ]),
])
