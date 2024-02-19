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
        title: 'KoRoad Verify Driver License Error Rate',
        custom: {
          name: 'koroad-verify-driver-license-error-rate',
          query: '(sum(rate(koroad_verify_driving_license_success{namespace="production"}[1h])) OR vector(0)) / sum(rate(koroad_verify_driving_license_attempts{namespace="production"}[1h]) > 0) * 100',
          alias: 'error verify driver license',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '1h',
        message: 'Error ratio of verify driver license above 10%',
        noDataState: 'ok',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'KoRoad Alerts',
  uid='koroad_alerts',
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
      channels: alerts.notifications.slackAlertsOnly,
      reducerType: 'avg',
    },
  },)
)
