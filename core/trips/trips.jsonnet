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

local targets = {
  allTripsStart: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query="SELECT $timeSeries AS t, count() as count FROM $table WHERE $timeFilter AND event_name = 'TRIP_START_SUCCESS' GROUP BY t ORDER BY t ASC ",
    table='trips_count_5m_v',
  ),
  tripsStartByCity: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query="SELECT $timeSeries AS t, count() as count FROM $table WHERE $timeFilter AND event_name = 'TRIP_END_SUCCESS' GROUP BY t ORDER BY t ASC ",
    table='trips_count_5m_v'
  ),
  tripsStartByIOTVersion: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query= "SELECT $timeSeries AS t, count() as c, city_id FROM $table WHERE $timeFilter AND event_name = 'TRIP_START_SUCCESS' GROUP BY t, city_id ORDER BY t ASC",
    table='trips_count_5m_v'
  ),
  allTripsEnd: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query="SELECT $timeSeries AS t, count() as c, city_id FROM $table WHERE $timeFilter AND event_name = 'TRIP_END_SUCCESS' GROUP BY t, city_id ORDER BY t ASC",
    table='trips_count_5m_v',
  ),
  tripsEndByCity: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query="SELECT $timeSeries AS t, count() as c, iot_version FROM $table WHERE $timeFilter and event_name = 'TRIP_START_SUCCESS' GROUP BY t, iot_version ORDER BY t ASC",
    table='trips_count_5m_v'
  ),
  tripsEndByIOTVersion: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,    
    query="SELECT $timeSeries AS t, count() as c, iot_version FROM $table WHERE $timeFilter and event_name = 'TRIP_END_SUCCESS' GROUP BY t, iot_version ORDER BY t ASC",
    table='trips_count_5m_v',
  ),
};

local alertConditions = {
  allTripsStart: {
    evaluator: {
      params: [
        40
      ],
      type: 'lt'
    },
    operator: {
      type: 'and'
    },
    query: {
      params: [
        'A',
        '5m',
        'now'
      ]
    },
    reducer: {
      params: [],
      type: 'avg'
    },
    type: 'query',
  },
  tripsStartByCity: {
      evaluator: {
        params: [
          10
        ],
        type: 'lt'
      },
      operator: {
        type: 'and'
      },
      query: {
        params: [
          'A',
          '5m',
          'now'
        ]
      },
      reducer: {
        params: [],
        type: 'avg'
      },
      type: 'query',
  },
  tripsStartByIOTVersion: {
      evaluator: {
        params: [
          10
        ],
        type: 'lt'
      },
      operator: {
        type: 'and'
      },
      query: {
        params: [
          'A',
          '5m',
          'now'
        ]
      },
      reducer: {
        params: [],
        type: 'avg'
      },
      type: 'query',
  },  
  allTripsEnd: {
    evaluator: {
      params: [
        40
      ],
      type: 'lt'
    },
    operator: {
      type: 'and'
    },
    query: {
      params: [
        'A',
        '5m',
        'now'
      ]
    },
    reducer: {
      params: [],
      type: 'avg'
    },
    type: 'query',
  },
  tripsEndByCity: {
      evaluator: {
        params: [
          10
        ],
        type: 'lt'
      },
      operator: {
        type: 'and'
      },
      query: {
        params: [
          'A',
          '5m',
          'now'
        ]
      },
      reducer: {
        params: [],
        type: 'avg'
      },
      type: 'query',
  },
  tripsEndByIOTVersion: {
      evaluator: {
        params: [
          10
        ],
        type: 'lt'
      },
      operator: {
        type: 'and'
      },
      query: {
        params: [
          'A',
          '5m',
          'now'
        ]
      },
      reducer: {
        params: [],
        type: 'avg'
      },
      type: 'query',
  },      
};

local panels = {
  allTripsStart: panel.new(title='Number of trips start globally', time_shift='5m')
    .addTargets([targets.allTripsStart])
    .addAlert(
      name='Number of trips start globally alert',
      message='Trips start are low globally (<40)',
      notifications=[alertsHelper.slackBusinessMonitoring],
    )
    .addConditions([alertConditions.allTripsStart]),

  tripsStartByCity: panel.new(title='Number of trips start by city ID', time_shift='5m')
    .addTargets([targets.tripsStartByCity])
    .addAlert(
      name='Number of trips start by city ID alert',
      notifications=[alertsHelper.slackBusinessMonitoring],
      forDuration='1h',
    )
    .addConditions([alertConditions.tripsStartByCity]),

  tripsStartByIOTVersion: panel.new(title='Number of trips start by IOT version', time_shift='5m')
    .addTargets([targets.tripsStartByIOTVersion])
    .addAlert(
      name='Number of trips start by IOT version alert',
      notifications=[alertsHelper.slackBusinessMonitoring],
      forDuration='1h',
    )
    .addConditions([alertConditions.tripsStartByIOTVersion]),    
  
  allTripsEnd: panel.new(title='Number of trips end globally', time_shift='5m')
    .addTargets([targets.allTripsEnd])
    .addAlert(
      name='Number of trips end globally alert',
      message='Trips end are low globally (<40)',
      notifications=[alertsHelper.slackBusinessMonitoring],
    )
    .addConditions([alertConditions.allTripsEnd]),

  tripsEndByCity: panel.new(title='Number of trips end by city ID', time_shift='5m')
    .addTargets([targets.tripsEndByCity])
    .addAlert(
      name='Number of trips end by city ID alert',
      notifications=[alertsHelper.slackBusinessMonitoring],
      forDuration='1h',
    )
    .addConditions([alertConditions.tripsEndByCity]),

  tripsEndByIOTVersion: panel.new(title='Number of trips end by IOT version', time_shift='5m')
    .addTargets([targets.tripsEndByIOTVersion])
    .addAlert(
      name='Number of trips end by IOT version alert',
      notifications=[alertsHelper.slackBusinessMonitoring],
      forDuration='1h',
    )
    .addConditions([alertConditions.tripsEndByIOTVersion]),
};

local rows = {
  trips: row.new('Trips Health').addPanels([
    panel.fullRow(p)
    for p in [
      panels.allTripsStart,
      panels.tripsStartByCity,
      panels.tripsStartByIOTVersion,
      panels.allTripsEnd,
      panels.tripsEndByCity,
      panels.tripsEndByIOTVersion,
    ]
  ]),
};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Trips Monitoring',
  uid='jwebb_trips',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  rows.trips,
])
