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
  target.equalsFilter('service', 'analytics-watchdog'),
);


// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Scheduled Queries',
    alerts: [
      {
        title: 'Zero byte tables > 0',
        counter: { name: 'bq-zero-byte-table' },
        threshold: 0,
        reducerType: 'sum',
        evaluateFor: '1m',
        message: 'Some tables are empty',
      },
    ],
  },
  {
    row: 'BQ data completeness alerts',
    alerts: [
      {
        title: '[bq] mutations > 10000',
        custom: { query: 'sum(bq_mutations_hourly) by (table_id)', alias: '{{table_id}}' },
        threshold: 10000,
        reducerType: 'max',
        evaluateFor: '30m',
        evaluateEvery: '1m',
        message: 'Some tables have too many mutations',
      },
    ],
  },
  {
    row: 'BQ scheduled queries',
    alerts: [
      {
        title: '[bq] scheduled queries fails',
        counter: { name: 'bq-scheduled-query', filters: target.equalsFilter('scheduled_query_state', 'FAILED') },
        threshold: 0,
        reducerType: 'sum',
        evaluateFor: '1m',
        message: 'Scheduled query failure',
      },
      {
        title: '[bq] failed scheduled queries',
        gauge: {
          name: 'bq-scheduled-query-failed',
          groupBys: ['scheduled_query_name'],
          func: target.gaugeFuncs.sum.func,
        },
        threshold: 0,
        reducerType: 'sum',
        evaluateFor: '1m',
        message: 'Names of failed scheduled queries',
      },
    ],
  },
  {
    row: 'Redash',
    alerts: [
      {
        title: 'DB CPU Usage',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/cpu/utilization',
          filters: gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-redash'),
          format: 'percentunit',
        },
        threshold: 0.75,
        message: 'High CPU Usage',
        evaluateFor: '15m',
      },
      {
        title: 'DB Memory Usage',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/memory/total_usage',
          filters: gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-redash'),
          format: 'bytes',
        },
        threshold: 3 * 1024 * 1024 * 1024,
        message: 'High Memory Usage',
        evaluateFor: '15m',
      },
    ],
  },
  {
    row: 'Data Completeness',
    alerts: [
      {
        title: 'Snapshot row count difference > 0',
        gauge: {
          name: 'bq-row-diff-snapshot-tables',
          groupBys: ['table_id'],
        },
        threshold: 100,
        reducerType: 'max',
        evaluateFor: '1h',
        message: 'Some snapshot tables are not in sync',
      },
      {
        title: 'Partition row count difference > 0',
        gauge: {
          name: 'bq-row-diff-partition-tables',
          groupBys: ['table_id'],
        },
        threshold: 100,
        reducerType: 'max',
        evaluateFor: '1h',
        message: 'Some partition tables are not in sync',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts',
  uid='bigquery_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slackData],
  },
  counters+: {
    func: 'delta',
    filters: serviceFilter,
  },
  gcpGauges+: {
    gcpHelpers: gcpHelpers,
  },
  gauges+: {
    filters: serviceFilter,
  },
}))
