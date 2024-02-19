local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';
local supportedCountries = import '../business_health_metrics/countries.json';

local helpers = clickhouse.init();
local panel = helpers.panel;
local graphPanel = grafana.graphPanel;
local target = helpers.target;

local dailyAverageUserQuery() =
  |||
    with src as (
        select 
            *,
            SUBSTRING(appVersion, 6, position(appVersion, '-', 6) - position(appVersion, '-', 1)-1) as app_version,
            if(SUBSTRING(platformVersion,1, 7) = 'Android', 'android', 'ios') as operating_system,
            coalesce(parseDateTimeBestEffortOrZero(_client_event_time), event_time) as client_event_time
        from 
            $table  
        where $timeFilter
        and event_name = 'sceneLoaded'
        and countryId in ($country_id)
        and app_version in ($app_version)
    ),

    events as (
        select
            user_id,
            app_version,
            operating_system,
            event_name,
            countryId,
            if (client_event_time <= event_time, client_event_time, event_time) as event_time
        from src
        where $timeFilterByColumn(client_event_time)
    ),

    days as (
        select count(distinct toDate(event_time)) as total_day from events
    )

    select
        multiIf(countryId = '51', 'South Korea', countryId = '9','Australia', countryId = '4','Malaysia', countryId = '10','New Zealand','Not in list') as country,
        app_version as appVersion,
        operating_system as operatingSystem,
        count(distinct user_id)/(select total_day from days) as dailyAverageUser
    from events
    group by 1,2,3
  |||
;

local dailyUserQuery() =
  |||
    with src as (
        select 
            *,
            SUBSTRING(appVersion, 6, position(appVersion, '-', 6) - position(appVersion, '-', 1)-1) as app_version,
            if(SUBSTRING(platformVersion,1, 7) = 'Android', 'android', 'ios') as operating_system,
            coalesce(parseDateTimeBestEffortOrZero(_client_event_time), event_time) as client_event_time
        from 
            $table  
        where $timeFilter
        and event_name = 'sceneLoaded'
        and countryId in ($country_id)
        and app_version in ($app_version)
    ),

    events as (
        select
            user_id,
            app_version,
            operating_system,
            event_name,
            multiIf(countryId = '51', 'South Korea', countryId = '9','Australia', countryId = '4','Malaysia', countryId = '10','New Zealand','Not in list') as country,
            if (client_event_time <= event_time, client_event_time, event_time) as event_time
        from src
        where $timeFilterByColumn(client_event_time)
    )

    select
        toDate(event_time) as time,
        concat(country,'-',app_version,'-',operating_system) as unique,
        count(distinct user_id) as dailyUser
    from events
    group by time, unique
  |||
;

local dailyAverageUserTarget() =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='event_time',
    query=dailyAverageUserQuery(),
    table='app_events',
  ) {
    format: 'table',
  }
;

local dailyUserTarget() =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='event_time',
    query=dailyUserQuery(),
    table='app_events',
  ) {
    format: 'time_series',
  }
;

grafana.dashboard.new(
  'Users Distributions',
  uid='users_distributions',
  refresh='90s',
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
    name='country_id',
    label='Country',
    query=std.join(',', [std.format("%s", std.toString(k.id)) for k in supportedCountries]),
    valuelabels={
      [std.format("%s", std.toString(k.id))]: k.name
      for k in supportedCountries
    },
    multi=true,
    includeAll=true,
    current=std.toString(supportedCountries[0].id),
  )
)

.addRows([
  row.new('Users Distributions').addPanels([
    panel.halfRow(
      panel.new(title='Users Distributions DAU')
      .addTargets([dailyAverageUserTarget()])
    ) { type: 'table' },
    panel.halfRow(
      graphPanel.new(
        title='Screen Loaded Daily'
        )
        .addTargets([dailyUserTarget()])
        { type: 'timeseries'}
    ),
  ]),
])