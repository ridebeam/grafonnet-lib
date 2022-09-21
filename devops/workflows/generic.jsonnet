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

local workflowFilters = target.combineFilters(
  target.equalsFilter('cluster', '$cluster'),
  target.equalsFilter('workflow_name', '$workflow'),
);

local targets = {
  execution: {
    result: target.counter(
      metric='argo_workflows_exec_result',
      filters=workflowFilters,
      groupBys=['status'],
      withServiceFilters=false,
    ),
    successRate: target.ratio(
      metric='argo_workflows_exec_result',
      filters=workflowFilters,
      numeratorFilters=target.equalsFilter('status', 'Succeeded'),
      withServiceFilters=false,
    ),
    duration: target.gauges(
      metric='argo_workflows_exec_duration',
      filters=workflowFilters,
      groupBys=['status'],
      withServiceFilters=false,
    ),
  },
};

local panels = {
  execution: {
    result: panel.counter('Workflow Execution Result', legend_show=true).addTargets([
      targets.execution.result,
    ]),
    successRate: panel.counter('Workflow Execution Success Rate', format='percentunit').addTargets([
      targets.execution.successRate,
    ]),
    duration: panel.timeLog2('Worflow Execution Duration', legend_show=true).addTargets([
      targets.execution.duration.avg,
      targets.execution.duration.max,
    ]),
  },
};

local rows = {
  execution: row.new('Workflow Execution').addPanels([
    panel.halfRow(p)
    for p in [
      panels.execution.result,
      panels.execution.successRate,
      panels.execution.duration,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Workflows Overview',
  uid='workflows_generic',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='cluster',
    query='staging-sg,core-sg',
    current='core-sg',
  )
)

.addTemplate(
  template.new(
    name='workflow',
    datasource=null,
    query='label_values(argo_workflows_exec_result, workflow_name)',
    current='dbt-run',
    refresh=1,
    sort=1,
  )
)

.addRows([
  rows.execution,
])
