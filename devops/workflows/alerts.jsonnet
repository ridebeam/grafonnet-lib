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
    row: 'Tasks',
    alerts: [
      {
        title: 'Task execution failed(threshold 0)',
        custom: {
          name: 'workflow-task-execution-fail-rate',
          query: 'increase(argo_workflows_task_exec_result{cluster="core-sg", status="Failed", task_name!="create-tasks"}[5m])',
          alias: '{{task_name}}',
        },
        threshold: 0,
        reducerType: 'max',
        thresholdType: 'gt',
        message: '<https://grafana.devops.ridebeam.cloud/d/workflows_tasks_overview/tasks-overview?orgId=1&from=now-24h&to=now-1m|Go to dashboard>',
        noDataState: 'ok',
      },
      {
        title: 'Task execution failed(threshold 2)',
        custom: {
          name: 'workflow-task-execution-fail-rate',
          query: 'increase(argo_workflows_task_exec_result{cluster="core-sg", status="Failed", task_name="create-tasks"}[15m])',
          alias: '{{task_name}}',
        },
        threshold: 2,
        reducerType: 'max',
        thresholdType: 'gt',
        evaluateFor: '10m',
        message: '<https://grafana.devops.ridebeam.cloud/d/workflows_tasks_overview/tasks-overview?orgId=1&from=now-24h&to=now-1m|Go to dashboard>',
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
