local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;


// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Fail Rate',
    alerts: [
      {
        title: 'Task execution fail rate',
        custom: {
          name: 'workflow-task-execution-fail-rate',
          query: '(sum(rate(argo_workflows_task_exec_result{cluster="production", status="Failed"}[5m])) by (task_name) OR vector(0)) / sum(rate(argo_workflows_task_exec_result{cluster="production"}[5m])) by (task_name) * 100',
          alias: 'workflow task execution fail rate',
        },
        threshold: 1,
        thresholdType: 'gt',
        message: 'Task fail rate is more than 1%',
        noDataState: 'ok',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Workflows Alerts',
  uid='workflows_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slackData],
  },
}))
