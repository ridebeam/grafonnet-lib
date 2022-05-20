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
  },
};

local rows = {
  serviceUptime: row.new('Flink Health').addPanels([
    panel.fullRow(p)
    for p in [
      panels.serviceUptime.jobmanagerUptime,
      panels.serviceUptime.jobmanagerDowntime,
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
    query='flink-example-jobmanager',
    current='flink-example-jobmanager',
    hide='variable',
  )
)

.addRows([
  rows.serviceUptime,
])
