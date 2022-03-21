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


// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'CDC',
    alerts: [
      {
        title: 'Wallet CDC Snapshots aborted > 0',
        gauge: {
          name: 'debezium_metrics_snapshot_aborted',
          filters: target.combineFilters(
            target.equalsFilter('namespace', 'production'),
            target.equalsFilter('service', 'wallet-cdc'),
          ),
        },
        threshold: 1,
        reducerType: 'max',
        evaluateFor: '10m',
        evaluateEvery: '1h',
        message: 'Some snapshot tables are not in sync',
      },
      {
        title: 'Trip CDC Snapshots aborted > 0',
        gauge: {
          name: 'debezium_metrics_snapshot_aborted',
          filters: target.combineFilters(
            target.equalsFilter('namespace', 'production'),
            target.equalsFilter('service', 'trip-cdc'),
          ),
        },
        threshold: 1,
        reducerType: 'max',
        evaluateFor: '10m',
        evaluateEvery: '1h',
        message: 'Some snapshot tables are not in sync',
      },
      {
        title: 'Settings CDC Snapshots aborted > 0',
        gauge: {
          name: 'debezium_metrics_snapshot_aborted',
          filters: target.combineFilters(
            target.equalsFilter('namespace', 'production'),
            target.equalsFilter('service', 'settings-cdc'),
          ),
        },
        threshold: 1,
        reducerType: 'max',
        evaluateFor: '10m',
        evaluateEvery: '1h',
        message: 'Some snapshot tables are not in sync',
      },
      {
        title: 'Beam API CDC Snapshots aborted > 0',
        gauge: {
          name: 'debezium_metrics_snapshot_aborted',
          filters: target.combineFilters(
            target.equalsFilter('namespace', 'production'),
            target.equalsFilter('service', 'cdc-postgres-cdc'),
          ),
        },
        threshold: 1,
        reducerType: 'max',
        evaluateFor: '10m',
        evaluateEvery: '1h',
        message: 'Some snapshot tables are not in sync',
      },
      {
        title: 'Beam API Snapshots aborted > 0',
        gauge: {
          name: 'debezium_metrics_snapshot_aborted',
          filters: target.combineFilters(
            target.equalsFilter('namespace', 'production'),
            target.equalsFilter('service', 'cdc-postgres-interval-snapshot'),
          ),
        },
        threshold: 1,
        reducerType: 'max',
        evaluateFor: '10m',
        evaluateEvery: '1h',
        message: 'Some snapshot tables are not in sync',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'CDC Production Alerts',
  uid='cdc_alerts',
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
}))
