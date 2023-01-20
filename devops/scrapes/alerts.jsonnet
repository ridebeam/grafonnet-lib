local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';

local alertDefinitions = [
  {
    row: 'Tanda',
    alerts: [
      {
        title: 'Tanda Failed Workflows',
        custom: {
          name: 'tanda-workflow-execution-fail-rate',
          query: 'sum(rate(argo_workflows_exec_result{cluster="core-sg", workflow_name=~"^tanda.*", status="Failed"}[$__interval])) by (workflow_name) > 0',
          alias: '{{workflow_name}}',
        },
        reducerType: 'sum',
        threshold: 0,
        thresholdType: 'gt',
        message: '<https://grafana.devops.ridebeam.cloud/d/scrapes_alerts/scrapes-alerts?orgId=1&from=now-24h&to=now-1m|Go to dashboard',
        noDataState: 'ok',
      },
      {
        title: 'Tanda Failed Workflow Tasks',
        custom: {
          name: 'tanda-workflow-task-execution-fail-rate',
          query: 'sum(rate(argo_workflows_task_exec_result{cluster="core-sg", task_name=~"^tanda.*", status="Failed"}[$__interval])) by (task_name) > 0',
          alias: '{{task_name}}',
        },
        reducerType: 'sum',
        threshold: 0,
        thresholdType: 'gt',
        message: '<https://grafana.devops.ridebeam.cloud/d/scrapes_alerts/scrapes-alerts?orgId=1&from=now-24h&to=now-1m|Go to dashboard',
        noDataState: 'ok',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Scrapes Alerts',
  uid='scrapes_alerts',
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
