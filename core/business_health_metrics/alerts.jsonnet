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

local citiesWithAlerts = std.filter(function(c) std.get(c, 'alerts', default=false), supportedCities);

local query =
  |||
    with
    cities as (
        select arrayJoin(%s) as city_id
    ),
    raw_events as (
        SELECT
            event_time,
            event_name,
            e.city_id,
            properties
        FROM $table e
        RIGHT JOIN cities c ON c.city_id = e.city_id
        WHERE event_name IN ('TRIP_START_SUCCESS')
        AND $timeFilter
    ),
    trips_count_30m AS (
        SELECT
            city_id,
            toStartOfInterval(event_time, INTERVAL 30 minute) AS time_bucket,
            count() as count
        FROM raw_events
        GROUP BY time_bucket, city_id
    ),
    trips_count_30m_forecast AS (
        select
            toDateTime(time_bucket) as time_bucket,
            city_id,
            g.name as city_name,
            if(toInt64(yhat_lower) < 0, 0, toInt64(yhat_lower)) as yhat_lower,
            yhat_upper,
            yhat,
            y
        from executable(
            'table_forecast_multi.py trips',
            'TabSeparated',
            'city_id UInt64, time_bucket String, y Float64, yhat Float64, yhat_lower Float64, yhat_upper Float64',
            (select city_id, time_bucket, count from trips_count_30m order by time_bucket asc)) e
        left join georegions g ON g.id = e.city_id
    )
    select
        (toUInt32(toDateTime(time_bucket)) * 1000) as t,
        city_name as city_id,
        y-yhat_lower as dist
    from trips_count_30m_forecast
    where toDateTime(time_bucket) < toStartOfInterval(now(), interval 30 minute)
    order by time_bucket asc
  ||| % [[c.id for c in citiesWithAlerts]]
;

local targets = {
  tripsDist: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=query,
    table='events',
    dateTimeColDataType='event_time',
  ),
};

local alertConditions = {
  trips: {
    type: 'query',
    query: {
      params: [
        'A',
        '2h',
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

local panels = {
  trips: panel.new(title='Trips below forecast threshold')
         .setFieldConfigDefaults(fieldConfigDefaults)
         .addTargets([targets.tripsDist])
         .addAlert(
    name='Trips below forecast threshold',
    forDuration='5m',
    frequency='1m',
    notifications=[alertsHelper.slackBusinessMonitoringWarning],
  )
         .addConditions([alertConditions.trips]),
};

local rows = {
  trips: row.new('Trips').addPanels([
    panel.fullRow(p)
    for p in [
      panels.trips,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Alerts',
  uid='business_health_metrics_alerts',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  rows.trips,
])
