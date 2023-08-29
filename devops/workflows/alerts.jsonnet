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
        title: 'Workflow execution failed',
        custom: {
          name: 'workflow-execution-fail-rate',
	  // Manually exclude dbt-bq-ci-test, proper filter will be done in https://beammobility.atlassian.net/browse/DP-1022
          query: 'increase(sum(argo_workflows_exec_result{cluster="core-sg", status="Failed", workflow_name!="dbt-bq-ci-test"}[5m]) by (workflow_name))',
          alias: '{{workflow_name}}',
        },
        threshold: 0,
        reducerType: 'max',
        thresholdType: 'gt',
        message: '<https://grafana.devops.ridebeam.cloud/d/workflows_tasks_overview/tasks-overview?orgId=1&from=now-24h&to=now-1m|Go to dashboard>\n<https://argo-workflow.core.ridebeam.cloud/workflows/production?phase=Failed|Check failed workflows>',
        noDataState: 'ok',
      },
      {
        title: 'Workflow execution duration(threshold 35 minutes)',
        custom: {
          name: 'workflow-execution-duration',
          query: 'argo_workflows_exec_duration_in_real_time{cluster="core-sg"}[24h]',
          alias: '{{workflow_name}}',
        },
        threshold: 2100,
        reducerType: 'max',
        thresholdType: 'gt',
        message: '<https://grafana.devops.ridebeam.cloud/d/workflows_alerts/workflows-alerts?orgId=1|Check the alert>',
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
