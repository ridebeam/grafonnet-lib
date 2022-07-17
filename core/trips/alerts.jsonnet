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


local alertConditions = {
  trips_by_city_threshold: {
    type: 'query',
    query: {
      params: [
        'A',
        '30m',
        'now',
      ],
    },
    reducer: {
      type: 'avg',
      params: [],
    },
    evaluator: {
      type: 'lt',
      params: [
        0,
      ],
    },
    operator: {
      type: 'and',
    },
  },
  trips_peskin_ratio: {
    type: 'query',
    query: {
      params: [
        'A',
        '1h',
        'now-30m',
      ],
    },
    reducer: {
      type: 'avg',
      params: [],
    },
    evaluator: {
      type: 'gt',
      params: [
        0.2,
      ],
    },
    operator: {
      type: 'and',
    },
  },
};

local panels = {
  trips_start_threshold: panel.new(title='Trips start -1 stddev', time_shift='5m')
                         .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, toString(city_id) as city_id, max(count - threshold_1Z) FROM $table WHERE $timeFilter AND event_name = 'TRIP_START_SUCCESS' GROUP BY t, city_id ORDER BY t",
      formattedQuery="SELECT $timeSeries as t, toString(city_id) as city_id, max(count - threshold_1Z) FROM $table WHERE $timeFilter AND event_name = 'TRIP_START_SUCCESS' GROUP BY t, city_id ORDER BY t",
      table='trips_start_wow_final_v',
    ),
  ])
                         .addAlert(
    name='Trips start below threshold 1 stddev',
    forDuration='1m',
    frequency='1m',
    notifications=[alertsHelper.slackBusinessMonitoring],
  )
                         .addConditions([alertConditions.trips_by_city_threshold]),
  trips_peskin_ratio: panel.new(title="Trips' Peskin Ratio")
                      .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, toString(city_id) as city, sum(case when status_type = 'failed_rides' then count else 0 end) / sum(case when status_type = 'successful_rides' then count else 0 end) as peskin_ratio FROM $table WHERE $timeFilter GROUP BY city, t ORDER BY t",
      table='trips_peskin_ratio_30m_v',
      formattedQuery="SELECT $timeSeries as t, toString(city_id) as city, sum(case when status_type = 'failed_rides' then count else 0 end) / sum(case when status_type = 'successful_rides' then count else 0 end) as peskin_ratio FROM $table WHERE $timeFilter GROUP BY city, t ORDER BY t",
    ),
  ])
                      .addAlert(
    name='Trips peskin ratio  alert',
    message='Peskin ratio  is above 0.1, number of failed trips are greater than 10% of successful trips in the last 30 minutes.',
    forDuration='1m',
    frequency='1m',
    notifications=[alertsHelper.slackBusinessMonitoring],
  )
                      .addConditions([alertConditions.trips_peskin_ratio]),
};

local rows = {
  trips_start_with_threshold: row.new('Trips start with threshold').addPanels([
    panel.fullRow(panels.trips_start_threshold),
  ]),
  trips_peskin_ratio: row.new('Trips Peskin Ratio').addPanels([
    panel.fullRow(panels.trips_peskin_ratio),
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Trips Alerts',
  uid='jwebb_trips_alerts',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  rows.trips_start_with_threshold,
  rows.trips_peskin_ratio,
])
