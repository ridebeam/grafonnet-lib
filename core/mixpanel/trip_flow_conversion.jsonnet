local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local tripFlowConversionQuery() =
  |||
    with src as (
        select 
            *,
            SUBSTRING(appVersion, 6, position(appVersion, '-', 6) - position(appVersion, '-', 1)-1) as app_version,
            coalesce(parseDateTimeBestEffortOrNull(_client_event_time), event_time) as client_event_time
        from 
            $table
        where  event_name in ['startTripValidationBegin', 'startTripValidationCompleted', 'startTripBegin', 'endTripBegin', 'endTripCompleted']
        and $timeFilter
        and app_version in ($app_version)
        ),

        events as (
        select
            user_id,
            app_version,
            event_name,
            success,
            sceneName,
            if (client_event_time <= event_time, client_event_time, event_time) as event_time
        from src
        ),

        step1 as (
        select 
            *
        from events
        where event_name = 'startTripValidationBegin'
        ),

        step2 as (
        select 
            *
        from events
        where  
            success = 'true'
            and event_name = 'startTripValidationCompleted'
        ),

        step3 as (
        select 
            *
        from events
        where event_name = 'startTripBegin'
        ),

        step4 as (
        select 
            *
        from events
        where event_name = 'endTripBegin'
        ),

        step5 as (
        select 
            *
        from events
        where 
            success = 'true'
            and event_name = 'endTripCompleted'
        ),
        joined_table as (
        select
            s1.user_id,
            s1.event_time as s1_event_time,
            s2.user_id as s2_user_id,
            s2.event_time as s2_event_time,
            s3.user_id as s3_user_id,
            s3.event_time as s3_event_time,
            s4.user_id as s4_user_id,
            s4.event_time as s4_event_time,
            s5.user_id as s5_user_id,
            s5.event_time as s5_event_time
        from step1 as s1
        left join step2 as s2
        on s1.user_id = s2.user_id
            and s1.app_version = s2.app_version
        left join step3 as s3
        on s3.user_id = s2.user_id
            and s3.app_version = s2.app_version  
        left join step4 as s4
        on s4.user_id = s3.user_id
            and s4.app_version = s3.app_version  
        left join step5 as s5
        on s5.user_id = s4.user_id
            and s5.app_version = s4.app_version
        where ( s1.event_time <= s2.event_time or isNull(s2.user_id))
            and (s2.event_time <= s3.event_time or isNull(s3.user_id))
            and (s3.event_time <= s4.event_time or isNull(s4.user_id))
            and (s4.event_time <= s5.event_time or isNull(s5.user_id))
        ) ,
        counter as (
            select 
                count(1) as step1, 
                countIf(isNotNull(s2_user_id)) as step2 ,
                countIf(isNotNull(s3_user_id)) as step3 ,
                countIf(isNotNull(s4_user_id)) as step4 ,
                countIf(isNotNull(s5_user_id)) as step5
            from joined_table
        ) 
        Select 
            1,
            100 as startTripValidationBegin,
            step2/step1 * 100 as startTripValidationCompleted,
            step3/step2 * 100 as startTripBegin,
            step4/step3 * 100 as endTripBegin,
            step5/step4 * 100 as endTripCompleted
        FROM counter
  |||
;

local tripFlowConversionCountQuery() =
  |||

    with src as (
        select 
            *,
            SUBSTRING(appVersion, 6, position(appVersion, '-', 6) - position(appVersion, '-', 1)-1) as app_version,
            coalesce(parseDateTimeBestEffortOrNull(_client_event_time), event_time) as client_event_time
        from 
            $table
        where  event_name in ['startTripValidationBegin', 'startTripValidationCompleted', 'startTripBegin', 'endTripBegin', 'endTripCompleted']
        and $timeFilter
        and app_version in ($app_version)
        ),

        events as (
        select
            user_id,
            app_version,
            event_name,
            success,
            sceneName,
            if (client_event_time <= event_time, client_event_time, event_time) as event_time
        from src
        ),

        step1 as (
        select 
            *
        from events
        where event_name = 'startTripValidationBegin'
        ),

        step2 as (
        select 
            *
        from events
        where  
            success = 'true'
            and event_name = 'startTripValidationCompleted'
        ),

        step3 as (
        select 
            *
        from events
        where event_name = 'startTripBegin'
        ),

        step4 as (
        select 
            *
        from events
        where event_name = 'endTripBegin'
        ),

        step5 as (
        select 
            *
        from events
        where 
            success = 'true'
            and event_name = 'endTripCompleted'
        ),
        joined_table as (
        select
            s1.user_id,
            s1.event_time as s1_event_time,
            s2.user_id as s2_user_id,
            s2.event_time as s2_event_time,
            s3.user_id as s3_user_id,
            s3.event_time as s3_event_time,
            s4.user_id as s4_user_id,
            s4.event_time as s4_event_time,
            s5.user_id as s5_user_id,
            s5.event_time as s5_event_time
        from step1 as s1
        left join step2 as s2
        on s1.user_id = s2.user_id
            and s1.app_version = s2.app_version
        left join step3 as s3
        on s3.user_id = s2.user_id
            and s3.app_version = s2.app_version  
        left join step4 as s4
        on s4.user_id = s3.user_id
            and s4.app_version = s3.app_version  
        left join step5 as s5
        on s5.user_id = s4.user_id
            and s5.app_version = s4.app_version
        where ( s1.event_time <= s2.event_time or isNull(s2.user_id))
            and (s2.event_time <= s3.event_time or isNull(s3.user_id))
            and (s3.event_time <= s4.event_time or isNull(s4.user_id))
            and (s4.event_time <= s5.event_time or isNull(s5.user_id))
        ) ,
        joined_table as (
        select
            s1.user_id,
            s1.event_time as s1_event_time,
            s2.user_id as s2_user_id,
            s2.event_time as s2_event_time,
            s3.user_id as s3_user_id,
            s3.event_time as s3_event_time,
            s4.user_id as s4_user_id,
            s4.event_time as s4_event_time,
            s5.user_id as s5_user_id,
            s5.event_time as s5_event_time
        from step1 as s1
        left join step2 as s2
        on s1.user_id = s2.user_id
            and s1.app_version = s2.app_version
        left join step3 as s3
        on s3.user_id = s2.user_id
            and s3.app_version = s2.app_version  
        left join step4 as s4
        on s4.user_id = s3.user_id
            and s4.app_version = s3.app_version  
        left join step5 as s5
        on s5.user_id = s4.user_id
            and s5.app_version = s4.app_version  
        where ( s1.event_time <= s2.event_time or isNull(s2.user_id))
            and (s2.event_time <= s3.event_time or isNull(s3.user_id))
            and (s3.event_time <= s4.event_time or isNull(s4.user_id))
            and (s4.event_time <= s5.event_time or isNull(s5.user_id))
        ) ,
        counter as (
            select 
                count(1) as startTripValidationBegin, 
                countIf(isNotNull(s2_user_id)) as startTripValidationCompleted ,
                countIf(isNotNull(s3_user_id)) as startTripBegin ,
                countIf(isNotNull(s4_user_id)) as endTripBegin ,
                countIf(isNotNull(s5_user_id)) as endTripCompleted
            from joined_table
        ) 
        Select 
            *
        FROM counter
  |||
;

local tripFlowConversionTarget() =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='event_time',
    query=tripFlowConversionQuery(),
    table='app_events',
  ) {
    format: 'time_series',
  }
;

local tripFlowConversionCountTarget() =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='event_time',
    query=tripFlowConversionCountQuery(),
    table='app_events',
  ) {
    format: 'table',
  }
;

grafana.dashboard.new(
  'Trip Flow Conversion',
  uid='trip_flow_conversion',
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

.addRows([
  row.new('Trip Flow Conversion').addPanels([
    panel.halfRow(
      panel.new(title='Trip Flow Conversion')
      .addTargets([tripFlowConversionTarget()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Trip Flow Conversion Count')
      .addTargets([tripFlowConversionCountTarget()])
    ) { type: 'table' },
  ]),
])