local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local env = 'production';
local serviceFilters = target.equalsFilter('namespace', '$env');

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Error Rate',
    alerts: [
      {
        title: 'Leanplum Push Message Error Rate',
        custom: {
          name: 'leanplum-push-message-error-rate',
          query: '(sum(rate(leanplum_push_message_failure{namespace="production"}[1h])) OR vector(0)) / sum(rate(leanplum_push_message_attempts{namespace="production"}[1h]) > 0) * 100',
          alias: 'error sending leanplum push message',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '1h',
        message: 'Error ratio of leanplum push message above 10%',
        noDataState: 'ok',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Leanplum Alerts',
  uid='leanplum_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(
  alerts.createRows(alertDefinitions, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.productionWarnings,
      reducerType: 'avg',
    },
  },)
)
