local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local gcp = import '../../helper/gcp.libsonnet';
local gcpHelpers = gcp.init('ridebeam-core');
local gcpTarget = gcpHelpers.target;
local gcpPanel = gcpHelpers.panel;
local m = gcpTarget.customMetric;
local l = gcpTarget.label;


// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'clickhouse'),
);


// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'General',
    alerts: [
      {
        title: 'Processes running',
        gauge: {
          name: 'ClickHouseAsyncMetrics_OSProcessesRunning',
          func: target.gaugeFuncs.max.func,
        },
        threshold: 1,
        thresholdType: 'lt',
        reducerType: 'max',
        evaluateFor: '30m',
        evaluateEvery: '1m',
        message: 'no processes are running',
      },
      {
        title: 'Processes blocked > 15',
        gauge: {
          name: 'ClickHouseAsyncMetrics_OSProcessesBlocked',
          func: target.gaugeFuncs.max.func,
        },
        threshold: 15,
        reducerType: 'max',
        evaluateFor: '30m',
        evaluateEvery: '1m',
        message: 'processes are blocked',
      },
      {
        title: 'Insert Query < 1',
        gauge: {
          name: 'ClickHouseProfileEvents_InsertQuery',
          func: target.gaugeFuncs.max.func,
        },
        threshold: 1,
        thresholdType: 'lt',
        reducerType: 'max',
        evaluateFor: '30m',
        evaluateEvery: '1m',
        message: 'no insert query on clickhouse',
      },
    ],
  },
  {
    row: 'Network',
    alerts: [
      {
        title: 'Send Errors > 0',
        gauge: {
          name: 'ClickHouseAsyncMetrics_NetworkSendErrors_eth0',
          func: target.gaugeFuncs.sum.func,
        },
        threshold: 0,
        reducerType: 'sum',
        evaluateFor: '1m',
        message: 'Errors on network send',
      },
      {
        title: 'Receive Errors > 0',
        gauge: {
          name: 'ClickHouseAsyncMetrics_NetworkReceiveErrors_eth0',
          func: target.gaugeFuncs.sum.func,
        },
        threshold: 0,
        reducerType: 'sum',
        evaluateFor: '1m',
        message: 'Errors on network receive',
      },
    ],
  },
  {
    row: 'Disk',
    alerts: [
      {
        title: 'Low Disk',
        gauge: {
          name: 'ClickHouseAsyncMetrics_DiskAvailable_default',
          func: target.gaugeFuncs.sum.func,
        },
        threshold: 20000000000*0.1, // 10% of disk available
        thresholdType: 'lt',
        reducerType: 'sum',
        evaluateFor: '1m',
        message: 'ClickHouse is running out of disk (10% left)',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Clickhouse Alerts',
  uid='clickhouse_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: alerts.notifications.dataAlerts,
  },
  gauges+: {
    filters: serviceFilter,
  },
}))
