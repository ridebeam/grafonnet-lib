local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;


local targets = {
  serviceUptime: {
    jobmanagerUptime: target.counter(
      metric='flink_jobmanager_job_uptime'
    ),
    jobmanagerDowntime: target.counter(
      metric='flink_jobmanager_job_downtime'
    ),
    checkpointsSucceeded: target.counter(
      metric='flink_jobmanager_job_numberOfCompletedCheckpoints'
    ),
    checkpointsFailed: target.counter(
      metric='flink_jobmanager_job_numberOfFailedCheckpoints'
    ),
  },
};

local panels = {
  serviceUptime: {
    jobmanagerUptime: panel.counter('Job Manager Uptime').addTargets([
      targets.serviceUptime.jobmanagerUptime,
    ]),
    jobmanagerDowntime: panel.counter('Job Manager Downtime').addTargets([
      targets.serviceUptime.jobmanagerDowntime,
    ]),
    checkpointsSucceeded: panel.counter('Checkpoint success').addTargets([
      targets.serviceUptime.checkpointsSucceeded,
    ]),
    checkpointsFailed: panel.counter('Checkpoint failure').addTargets([
      targets.serviceUptime.checkpointsFailed,
    ]),
  },
};

local rows = {
  serviceUptime: row.new('Flink Health').addPanels([
    panel.fullRow(p)
    for p in [
      panels.serviceUptime.jobmanagerUptime,
      panels.serviceUptime.jobmanagerDowntime,
      panels.serviceUptime.checkpointsSucceeded,
      panels.serviceUptime.checkpointsFailed,
    ]
  ]),
};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'JWebb Flink',
  uid='jwebb_flink',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
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
    query='flink-jwebb-clickhouse-jobmanager',
    current='flink-jwebb-clickhouse-jobmanager',
    hide='variable',
  )
)

.addRows([
  rows.serviceUptime,
])
