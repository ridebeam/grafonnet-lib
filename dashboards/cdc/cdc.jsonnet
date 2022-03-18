local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local lcdGauge = import '../../helper/lcd-gauge.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  general: {
    msBehindSource: target.gauges(metric='debezium_metrics_milli_seconds_behind_source').sum,
    snapshotsCompleted: target.gauges(metric='debezium_metrics_snapshot_completed').sum,
    snapshotsAborted: target.gauges(metric='debezium_metrics_snapshot_aborted').sum,
    snapshotsDurationInSeconds: target.gauges(metric='debezium_metrics_snapshot_duration_in_seconds').sum
  },
};

local panels = {
  msBehindSource: panel.new('Ms Behind Source').addTargets([targets.general.msBehindSource]),
  snapshotsCompleted: panel.new('Snapshots Completed').addTargets([targets.general.snapshotsCompleted]),
  snapshotsAborted: panel.new('Snapshots Aborted').addTargets([targets.general.snapshotsAborted]),
  snapshotsDurationInSeconds: panel.new('Snapshots Duration in Seconds').addTargets([targets.general.snapshotsDurationInSeconds]),
};

local rows = {
msBehindSource: row.new('Ms Behind Source').addPanels([
    panel.halfRow(p)
    for p in [
      panels.msBehindSource,
      panels.snapshotsCompleted,
      panels.snapshotsAborted,
      panels.snapshotsDurationInSeconds
    ]
  ]),

};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'CDC Monitoring',
  uid='cdc-monitoring-generic',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
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
    query='trip-cdc,wallet-cdc,settings-cdc,cdc-postgres-cdc,cdc-postgres-interval-snapshot',
    current='cdc-postgres-cdc',
  )
)

//.addTemplate(
//  template.new(
//    name='bq_table_id',
//    datasource=null,
//    query='label_values(bq_mutations_hourly, table_id)',
//    current='$__all',
//    multi=true,
//    includeAll=true,
//    refresh=1,
//    sort=1,
//    hide='variable',
//  )
//)

.addRows([
  rows.msBehindSource,
])
