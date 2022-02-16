local grafana = import './grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local alerts = import './helper/alerts.libsonnet';
local prom = import './helper/promql.libsonnet';
local lcdGauge = import './helper/lcd-gauge.libsonnet';
local k8s = import './dashboards/k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local gcp = import './helper/gcp.libsonnet';
local gcpHelpers = gcp.init('ridebeam-core');
local gcpTarget = gcpHelpers.target;
local gcpPanel = gcpHelpers.panel;
local m = gcpTarget.customMetric;
local l = gcpTarget.label;

local targets = {
  general: {
    zeroByte: target.counter(metric='bq-zero-byte-table', includeZero=true),
    tableSize: target.gauge(
      metric='bq-table-size',
      includeZero=true,
      groupBys=['table_id'],
      gaugeFunc=target.gaugeFuncs.sum,
    ) + {
      format: 'table',
      instant: true,
    },
  },
  dataCompleteness: {
    snapshotRowCount: target.gauge(
      metric='bq-row-diff-snapshot-tables',
      groupBys=['table_id'],
      includeZero=true,
      gaugeFunc=target.gaugeFuncs.max,
    ),
    test: target.gauge(
      metric='bq-table-size',
      includeZero=true,
      groupBys=['table_id'],
      gaugeFunc=target.gaugeFuncs.sum,
    ) + {
      format: 'table',
      instant: true,
    },
  },
};

local panels = {
  general: {
    zeroByte: panel.counter('Number of tables with zero bytes').addTargets([targets.general.zeroByte]),
    tableSize: panel.new('Table size').addTargets([targets.general.tableSize]) + lcdGauge.new(key='table_id', value='size', unit='decbytes')
  },
  dataCompleteness: {
    snapshotRowCount: panel.new('Snapshot row count difference').addTargets([
      targets.dataCompleteness.snapshotRowCount,
    ]),
  },
};

local rows = {
  general: row.new('General').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.zeroByte,
      panels.general.tableSize,
    ]
  ]),
  dataCompleteness: row.new('Data Completeness').addPanels([
    panel.halfRow(p)
    for p in [
      panels.dataCompleteness.snapshotRowCount,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'test bigquery monitoring',
  uid='bq-testing',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='analytics-watchdog',
    current='analytics-watchdog',
    hide='variable',
  )
)

.addRows([
  rows.general,
  rows.dataCompleteness,
])

// // we need to use non-templetized service filters for alerts
// local serviceFilter = target.combineFilters(
//   target.equalsFilter('namespace', 'production'),
//   target.equalsFilter('service', 'analytics-watchdog'),
// );


// // one entry per row, with a list of panels for each alert (counter/timing)
// local alertDefinitions = [
//   {
//     row: 'Data Completeness',
//     alerts: [
//       {
//         title: 'Snapshot row count difference > 0',
//         gauge: {
//           name: 'bq-row-diff-snapshot-tables',
//           groupBys: ['table_id'],
//         },
//         threshold: 0,
//         reducerType: 'max',
//         evaluateFor: '2h',
//         evaluateEvery: '30m',
//         message: 'Some snapshot tables are not in sync',
//       },
//       {
//         title: 'Partition row count difference > 0',
//         gauge: {
//           name: 'bq-row-diff-partitioned-tables',
//           groupBys: ['table_id'],
//         },
//         threshold: 0,
//         reducerType: 'max',
//         evaluateFor: '1h',
//         message: 'Some partitioned tables are not in sync',
//       },
//     ],
//   },
// ];

// // Make sure uid matches the name of the file
// grafana.dashboard.new(
//   'bigquery test Alerts',
//   uid='bq-testing-alerts',
//   refresh='30s',
//   timepicker=grafana.timepicker.new() { nowDelay: '1m' },
//   time_from='now-24h',
//   time_to='now-1m',
//   tags=['generated'],
//   editable=true,
// )
// .addRows(alerts.createRows(alertDefinitions, alerts.defaults {
//   alerts+: {
//     channels: alerts.notifications.productionWarnings,
//   },
//   gauges+: {
//     filters: serviceFilter,
//   },
// }))
