local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';
local alertsHelper = import '../../helper/alerts.libsonnet';
local vizHelper = import '../../helper/viz.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local supportedCities = import 'cities.json';
local supportedCountries = import 'countries.json';

local citiesWithAlerts = std.filter(function(c) std.get(c, 'alerts', default=false), supportedCities);
local countriesWithAlerts = std.filter(function(c) std.get(c, 'alerts', default=false), supportedCountries);


local cityQuery =
  |||
    with
    cities as (
        select arrayJoin(%s) as city_id
    ),
    time_series as (
      select 
          city_id,
          time_bucket, 
          count
      from $table t
      right join cities g ON g.city_id = t.city_id 
      where $timeFilter 
      order by time_bucket asc
    ),
    trips_count_city_forecast AS (
        select
            toDateTime(time_bucket) as time_bucket,
            city_id,
            if(toInt64(yhat_lower) < 0, 0, toInt64(yhat_lower * (1-(1-0.3)*rain_smoothed))) as yhat_lower,
            toInt64(yhat) as yhat,
            y
        from executable(
            'table_forecast_multi.py trips',
            'TabSeparated',
            'city_id UInt64, time_bucket String, y Float64, yhat Float64, yhat_lower Float64, yhat_upper Float64',
            (select * from time_series)) e
        left join jwebb.rain_30m w on toDateTime(e.time_bucket) = w.time_bucket and w.city_id = e.city_id
    )
    select
        (toUInt32(toDateTime(time_bucket)) * 1000) as t,
        toString(city_id) as city_id,
        g.name as city_name,
        toString(g.parent_id) as country_id,
        toString(time_bucket) as alerted_at,
        toString(sum(y)) as actual,
        toString(sum(yhat)) as forecasted,
        toString(sum(yhat_lower)) as threshold,
        sum(y-yhat_lower) as dist
    from trips_count_city_forecast t
    left join default.georegions g on t.city_id = g.id
    where toDateTime(time_bucket) < toStartOfInterval(now(), interval 30 minute)
    group by time_bucket, city_id, city_name, country_id, alerted_at
    order by time_bucket asc
  ||| % [[c.id for c in citiesWithAlerts]]
;

local countryQuery =
  |||
    with
    countries as (
        select arrayJoin(%s) as country_id
    ),
    time_series as (
      select 
          country_id,
          time_bucket, 
          count
      from $table t
      right join countries g ON g.country_id = t.country_id 
      where $timeFilter 
      order by time_bucket asc
    ),
    trips_count_country_forecast AS (
        select
            toDateTime(time_bucket) as time_bucket,
            country_id,
            toInt64(if(country_id = 51,
                if(toHour(toDateTime(time_bucket)) between 5 and 15, yhat_lower*0.5, if(yhat_lower < 0, 0, yhat_lower)),
                if(yhat_lower < 0, 0, yhat_lower)
            )) as yhat_lower,
            toInt64(yhat) as yhat,
            y
        from executable(
            'table_forecast_multi.py trips 0.9999',
            'TabSeparated',
            'country_id UInt64, time_bucket String, y Float64, yhat Float64, yhat_lower Float64, yhat_upper Float64',
            (select * from time_series))
    )
    select
        (toUInt32(toDateTime(time_bucket)) * 1000) as t,
        toString(country_id) as country_id,
        g.name as country_name,
        toString(time_bucket) as alerted_at,
        toString(sum(y)) as actual,
        toString(sum(yhat)) as forecasted,
        toString(sum(yhat_lower)) as threshold,
        sum(y-yhat_lower) as dist
    from trips_count_country_forecast t
    left join default.georegions g on t.country_id = g.id
    where toDateTime(time_bucket) < toStartOfInterval(now(), interval 30 minute)
    group by time_bucket, country_id, country_name, alerted_at
    order by time_bucket asc
  ||| % [[c.id for c in countriesWithAlerts]]
;

local globalQuery =
  |||
    with
    trips_count_global_forecast AS (
        select
            toDateTime(time_bucket) as time_bucket,
            toInt64(if(
              toHour(toDateTime(time_bucket)) between 5 and 15,
              yhat_lower*0.5,
              if(yhat_lower < 0, 0, yhat_lower)))
            as yhat_lower,
            toInt64(yhat) as yhat,
            y
        from executable(
            'table_forecast_multi.py trips 0.9999',
            'TabSeparated',
            'city_id UInt64, time_bucket String, y Float64, yhat Float64, yhat_lower Float64, yhat_upper Float64',
            (select 1 as city_id, time_bucket, count as count from $table where $timeFilter order by time_bucket asc)) e
    )
    select
        (toUInt32(toDateTime(time_bucket)) * 1000) as t,
        toString(time_bucket) as alerted_at,
        toString(y) as actual,
        toString(yhat) as forecasted,
        toString(yhat_lower) as threshold,
        y-yhat_lower as dist
    from trips_count_global_forecast
    where toDateTime(time_bucket) < toStartOfInterval(now(), interval 30 minute)
    order by time_bucket asc
  |||
;

local currentEventsLagQuery =
  |||
    WITH
        parts AS (SELECT max(max_time) AS latest_time FROM system.parts WHERE database = 'jwebb' AND table = 'events'),
        current AS (SELECT max(event_time) AS latest_time FROM jwebb.events)
    SELECT
        $timeSeries AS t,
        (SELECT latest_time FROM current) - (SELECT latest_time FROM parts) AS lag
    FROM $table
    WHERE $timeFilter
    GROUP BY t
    ORDER BY t
  |||
;

local futureEventsCountQuery =
  |||
    SELECT
        $timeSeries AS t,
        (SELECT COUNT(*) FROM $table WHERE event_time > now() + INTERVAL 10 MINUTE) AS count
    FROM $table
    WHERE $timeFilter
    GROUP BY t
    ORDER BY t
  |||
;

local targets = {
  trips: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=cityQuery,
    table='trips_count_30m',
  ),
  tripsCountry: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=countryQuery,
    table='trips_count_country',
  ),
  tripsGlobal: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=globalQuery,
    table='trips_count_global',
  ),
  currentEventsLag: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=currentEventsLagQuery,
    table='events',
    interval='10m',
    dateTimeColDataType='event_time',
  ),
  futureEventsCount: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=futureEventsCountQuery,
    table='events',
    interval='30m',
    dateTimeColDataType='event_time',
  ),
};

local alertConditions = {
  trips: {
    type: 'query',
    query: {
      params: [
        'A',
        '1h',
        'now',
      ],
    },
    reducer: {
      type: 'last',
      params: [],
    },
    evaluator: {
      type: 'lt',
      params: [
        0,
      ],
    },
  },
  currentEventsLag: {
    type: 'query',
    query: {
      params: [
        'A',
        '1h',
        'now',
      ],
    },
    reducer: {
      type: 'last',
      params: [],
    },
    evaluator: {
      type: 'gt',
      params: [
        5,
      ],
    },
  },
  futureEventsCount: {
    type: 'query',
    query: {
      params: [
        'A',
        '1h',
        'now',
      ],
    },
    reducer: {
      type: 'last',
      params: [],
    },
    evaluator: {
      type: 'gt',
      params: [
        0,
      ],
    },
  },
};

local fieldConfigDefaults = {
  custom: {
    fillOpacity: 0,
    lineWidth: 2,
    lineInterpolation: 'linear',
    gradientMode: 'scheme',
    showPoints: 'always',
    pointSize: 10,
    thresholdsStyle: {
      mode: 'area',
    },
  },
  color: {
    mode: 'thresholds',
  },
  thresholds: {
    mode: 'absolute',
    steps: [
      {
        value: null,
        color: 'red',
      },
      {
        value: -1,
        color: 'red',
      },
      {
        value: 0,
        color: 'green',
      },
    ],
  },
};

local overrides = [
  vizHelper.fieldOverride('tb', {
    custom: {
      hideFrom: {
        tooltip: true,
        viz: true,
        legend: true,
      },
    },
  }),
  vizHelper.fieldOverride('actual', {
    custom: {
      hideFrom: {
        tooltip: true,
        viz: true,
        legend: true,
      },
    },
  }),
  vizHelper.fieldOverride('forecasted', {
    custom: {
      hideFrom: {
        tooltip: true,
        viz: true,
        legend: true,
      },
    },
  }),
  vizHelper.fieldOverride('threshold', {
    custom: {
      hideFrom: {
        tooltip: true,
        viz: true,
        legend: true,
      },
    },
  }),
];

local cityMessage =
  |||
    City-level trip starts anomaly detected.
  |||
;

local countryMessage =
  |||
    Country-level trip starts anomaly detected.
  |||
;

local globalMessage =
  |||
    Global trip starts anomaly detected.
  |||
;

local currentEventsLagMessage =
  |||
    Current events missing in jwebb
  |||
;

local futureEventsCountMessage =
  |||
    Future events found in jwebb
  |||
;

local panels = {
  trips: panel.new(title='City-level trip starts below forecast threshold')
         .setFieldConfigDefaults(fieldConfigDefaults)
         .addTargets([targets.trips])
         .addAlert(
    name='City-level trip starts below forecast threshold',
    forDuration='5m',
    frequency='1m',
    message=cityMessage,
    alertRuleTags={
      metric: 'trips',
      type: 'city',
    },
    notifications=[alertsHelper.slackBusinessMonitoringWarning, alertsHelper.webhooks],
  )
         .addConditions([alertConditions.trips]),

  tripsCountry: panel.new(title='Country-level trip starts below forecast threshold')
                .setFieldConfigDefaults(fieldConfigDefaults)
                .addTargets([targets.tripsCountry])
                .addAlert(
    name='Country-level trip starts below forecast threshold',
    forDuration='5m',
    frequency='1m',
    message=countryMessage,
    alertRuleTags={
      metric: 'trips',
      type: 'country',
    },
    notifications=[alertsHelper.slackBusinessMonitoringWarning, alertsHelper.webhooks],
  )
                .addConditions([alertConditions.trips]),

  tripsGlobal: panel.new(title='Global trip starts below forecast threshold')
               .setFieldConfigDefaults(fieldConfigDefaults)
               .addTargets([targets.tripsGlobal])
               .addOverrides(overrides)
               .addAlert(
    name='Global trip starts below forecast threshold',
    forDuration='5m',
    frequency='1m',
    message=globalMessage,
    alertRuleTags={
      metric: 'trips',
      type: 'global',
    },
    notifications=[alertsHelper.slackBusinessMonitoringWarning, alertsHelper.webhooks],
  )
               .addConditions([alertConditions.trips]),

  currentEventsLag: panel.new(title='Current events lag')
                    .addTargets([targets.currentEventsLag])
                    .addAlert(
    name='Current events lag above threshold',
    forDuration='5m',
    frequency='1m',
    message=currentEventsLagMessage,
    notifications=[alertsHelper.coreSlackData],
  )
                    .addConditions([alertConditions.currentEventsLag]),

  futureEventsCount: panel.new(title='Future events found in jwebb')
                     .addTargets([targets.futureEventsCount])
                     .addAlert(
    name='Number of future events above threshold',
    forDuration='5m',
    frequency='1m',
    message=futureEventsCountMessage,
    notifications=[alertsHelper.coreSlackData],
  )
                     .addConditions([alertConditions.futureEventsCount]),
};

local rows = {
  trips: row.new('Trips').addPanels([
    panel.fullRow(p)
    for p in [
      panels.trips,
      panels.tripsCountry,
      panels.tripsGlobal,
    ]
  ]),
  events: row.new('Events').addPanels([
    panel.fullRow(p)
    for p in [
      panels.currentEventsLag,
      panels.futureEventsCount,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Alerts',
  uid='alerts',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  rows.trips,
  rows.events,
])
