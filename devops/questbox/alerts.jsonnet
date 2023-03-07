local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local gcp = import '../../helper/gcp.libsonnet';
local gcpHelpers = gcp.init('ridebeam-core');
local gcpTarget = gcpHelpers.target;
local gcpPanel = gcpHelpers.panel;
local m = gcpTarget.customMetric;
local l = gcpTarget.label;


local alertDefaults = {
  format: 'short',
  channels: alerts.notifications.opsEngineeringWarnings,
  thresholdType: 'gt',
  evaluateFor: '1m',
};

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'APIs',
    alerts: [
      {
        title: 'Get Task For Vehicle Latency',
        timer: {
          name: 'questbox-get-task-vehicle-timing',
          filters: target.equalsFilter('namespace', 'production'),
        },
        format: 's',
        threshold: 5,
        message: 'Latency of get task for vehicle increases above 5 seconds',
      },
      {
        title: 'Apply Action Latency',
        timer: {
          name: 'questbox-apply-action-timing',
          filters: target.equalsFilter('namespace', 'production'),
        },
        format: 's',
        threshold: 5,
        message: 'Latency of apply action increases above 5 seconds',
      },
      {
        title: 'Get Task for Vehicle Errors',
        custom: {
          name: 'rate-of-failure-ratio-get-task-vehicle',
          query: '((sum(rate(questbox_get_task_vehicle_failure{namespace="production"}[1m])) OR vector(0)) / sum(rate(questbox_get_task_vehicle_attempts{namespace="production"}[1m]))) * 100',
          alias: 'rate of failure ratio get task vehicle',
        },
        threshold: 30,
        message: 'Rate of errors of get task for vehicle increases above 30% of all requests',
      },
      {
        title: 'Apply Action Errors',
        custom: {
          name: 'rate-of-failure-ratio-apply-action',
          query: '((sum(rate(questbox_apply_action_failure{namespace="production"}[1m])) OR vector(0)) / sum(rate(questbox_apply_action_attempts{namespace="production"}[1m]))) * 100',
          alias: 'rate of failure ratio apply action',
        },
        threshold: 30,
        message: 'Rate of errors of apply action increases above 30% of all requests',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Questbox Alerts',
  uid='questbox_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: alerts.notifications.opsEngineeringWarnings,
    evaluateFor: '5m',
    reducerType: 'min',
    noDataState: 'ok',
  },
  gcpGauges+: {
    gcpHelpers: gcpHelpers,
  },
}))
