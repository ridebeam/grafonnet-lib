local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';
local sql = import './sql.libsonnet';

local helpers = clickhouse.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  allTripsStart: target.target(
    database='live_business',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=sql.allTripsSQL,
    table='trips_start_count',
  ),
  tripsStartByCity: target.target(
    database='live_business',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=sql.tripsByCitySQL,
    table='trips_start_count'
  ),
  tripsStartByIOTVersion: target.target(
    database='live_business',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=sql.tripsByIOTVersionSQL,
    table='trips_start_count'
  ),
  allTripsEnd: target.target(
    database='live_business',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=sql.allTripsSQL,
    table='trips_end_count',
  ),
  tripsEndByCity: target.target(
    database='live_business',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=sql.tripsByCitySQL,
    table='trips_end_count'
  ),
  tripsEndByIOTVersion: target.target(
    database='live_business',
    datasourceUID=clickhouse.dataSourceUIDProd,    
    query=sql.tripsByIOTVersionSQL,
    table='trips_end_count',
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
      notifications=[{ uid: 'QVVrMvj7z' }],
    )
    .addConditions([alertConditions.allTripsStart]),

  tripsStartByCity: panel.new(title='Number of trips start by city ID', time_shift='5m')
    .addTargets([targets.tripsStartByCity])
    .addAlert(
      name='Number of trips start by city ID alert',
      notifications=[{ uid: 'QVVrMvj7z' }],
      forDuration='1h',
    )
    .addConditions([alertConditions.tripsStartByCity]),

  tripsStartByIOTVersion: panel.new(title='Number of trips start by IOT version', time_shift='5m')
    .addTargets([targets.tripsStartByIOTVersion])
    .addAlert(
      name='Number of trips start by IOT version alert',
      notifications=[{ uid: 'QVVrMvj7z'}],
      forDuration='1h',
    )
    .addConditions([alertConditions.tripsStartByIOTVersion]),    
  
  allTripsEnd: panel.new(title='Number of trips end globally', time_shift='5m')
    .addTargets([targets.allTripsEnd])
    .addAlert(
      name='Number of trips end globally alert',
      message='Trips end are low globally (<40)',
      notifications=[{ uid: 'QVVrMvj7z'}],
    )
    .addConditions([alertConditions.allTripsEnd]),

  tripsEndByCity: panel.new(title='Number of trips end by city ID', time_shift='5m')
    .addTargets([targets.tripsEndByCity])
    .addAlert(
      name='Number of trips end by city ID alert',
      notifications=[{ uid: 'QVVrMvj7z' }],
      forDuration='1h',
    )
    .addConditions([alertConditions.tripsEndByCity]),

  tripsEndByIOTVersion: panel.new(title='Number of trips end by IOT version', time_shift='5m')
    .addTargets([targets.tripsEndByIOTVersion])
    .addAlert(
      name='Number of trips end by IOT version alert',
      notifications=[{ uid: 'QVVrMvj7z' }],
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
  'Trips',
  uid='jwebb_trips',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  rows.trips,
])
