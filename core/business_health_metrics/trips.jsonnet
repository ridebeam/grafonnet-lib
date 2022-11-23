local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';
local alertsHelper = import '../../helper/alerts.libsonnet';

local helpers = clickhouse.init();
local target = helpers.target;
local panel = helpers.panel;

// TODO: Make this queryable from Clickhouse.
// This is a list of cities that have alerts enabled.
local supportedCities = [
  { id: 121, name: 'Seoul' },
  { id: 16, name: 'Brisbane' },
  { id: 356, name: 'Daegu' },
  { id: 612, name: 'Goyang-Paju' },
  { id: 483, name: 'CheonanCity' },
  { id: 552, name: 'Cheongju' },
  { id: 12, name: 'Kuala Lumpur' },
  { id: 650, name: 'Gwangju' },
  { id: 13, name: 'Auckland' },
  { id: 416, name: 'Incheon' },
  { id: 370, name: 'ADLCity' },
  { id: 21, name: 'Canberra' },
  { id: 341, name: 'Seongnam-Suwon' },
  { id: 15, name: 'Wellington' },
  { id: 507, name: 'Busan' },
  { id: 349, name: 'Selangor' },
  { id: 553, name: 'Daejeon' },
  { id: 460, name: 'Townsville' },
  { id: 1118, name: 'Hobart' },
  { id: 891, name: 'Gunsan' },
  { id: 19, name: 'Sydney' },
  { id: 618, name: 'Gwangyang' },
  { id: 1425, name: 'Chuncheon' },
  { id: 1119, name: 'Launceston' },
  { id: 1121, name: 'Whangarei' },
  { id: 1096, name: 'Mackay' },
  { id: 1190, name: 'Esperance' },
  { id: 809, name: 'Palmerston North' },
  { id: 300, name: 'Bunbury' },
  { id: 580, name: 'Bangkok' },
  { id: 1519, name: 'Fethiye' },
  { id: 1529, name: 'Marmaris' },
  { id: 1036, name: 'PortDouglas' },
  { id: 994, name: 'Phuket' },
  { id: 1079, name: 'Rockingham' },
  { id: 1464, name: 'Bodrum' },
  { id: 1443, name: 'Pahang' },
  { id: 1462, name: 'Burnie' },
];

// TODO: simplify this with dbt view, it should be just a one-liner like:
//
//      select * from trips_count_30m_forecast(city_id)
//
local trips_query(city_id) =
  |||
    WITH
    raw_events as (
        SELECT
            event_time,
            event_name,
            city_id,
            properties
        FROM $table
        WHERE event_name IN ('TRIP_START_SUCCESS')
        AND $timeFilter
        AND city_id = %(city_id)s
    ),
    trips_count_30m AS (
        SELECT
            toStartOfInterval(event_time, INTERVAL 30 minute) AS time_bucket,
            count() as count
        FROM raw_events
        GROUP BY time_bucket
    )
    select
        (toUInt32(toDateTime(time_bucket)) * 1000) as t,
        yhat_lower,
        yhat_upper,
        yhat,
        y
    from executable(
        'table_forecast.py trips %(city_id)s',
        'TabSeparated',
        'time_bucket String, y Float64, yhat Float64, yhat_lower Float64, yhat_upper Float64',
        (select * from trips_count_30m order by time_bucket asc))
  ||| % { city_id: city_id }
;

local targets = {
  allTripsStart: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=trips_query('$city_id'),
    table='events',
    dateTimeColDataType='event_time',
  ),
};

local fieldOverride(name, properties) = {
  matcher: {
    id: 'byName',
    options: name,
  },
  properties: std.map(function(p) {
                id: 'custom.%s' % [p],
                value: properties.custom[p],
              }, std.objectFields(std.get(properties, 'custom', {})))
              + std.map(function(p) {
                id: p,
                value: properties[p],
              }, std.filter(function(p) p != 'custom', std.objectFields(properties))),
};

local overrides = [
  fieldOverride('yhat_upper', {
    custom: {
      fillBelowTo: 'yhat_lower',
      lineWidth: 0,
      fillOpacity: 20,
      lineInterpolation: 'linear',
      gradientMode: 'none',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'super-light-blue',
    },
    displayName: 'Threshold',
    min: 0,
  }),
  fieldOverride('yhat_lower', {
    custom: {
      lineWidth: 0,
      fillOpacity: 0,
      lineInterpolation: 'linear',
      hideFrom: {
        tooltip: false,
        viz: false,
        legend: true,
      },
    },
    min: 0,
  }),
  fieldOverride('yhat', {
    custom: {
      fillOpacity: 0,
      lineWidth: 3,
      lineInterpolation: 'linear',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'dark-blue',
    },
    displayName: 'Forecasted trips',
    min: 0,
  }),
  fieldOverride('y', {
    custom: {
      fillOpacity: 0,
      lineWidth: 0,
      pointSize: 6,
      showPoints: 'always',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'black',
    },
    displayName: 'Trips',
    min: 0,
  }),
];

local createPanel(title, target) =
  panel.new(title=title, time_shift='30m')
  .addTargets([target])
  .addOverrides(overrides)
;

local panels = {
  tripsCount: createPanel('Trips count (30m interval)', targets.allTripsStart),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Trips',
  uid='business_metrics_trips',
  refresh='15m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addTemplate(
  template.custom(
    name='city_id',
    label='City',
    query=std.join(',', [std.toString(k.id) for k in supportedCities]),
    valuelabels={
      [std.toString(k.id)]: k.name
      for k in supportedCities
    },
    current=std.toString(supportedCities[0].id),
  )
)

.addPanel(panels.tripsCount, gridPos={ x: 0, y: 0, w: 24, h: 15 })
