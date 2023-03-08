local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local env = 'production';
local service = 'loyalty';

// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', env),
  target.equalsFilter('service', service),
);

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Error Rate',
    alerts: [
      {
        title: 'Add Member Error Rate',
        custom: {
          name: 'add-member-error-rate',
          query: '(sum(rate(add_member_failed{namespace="production"}[10m])) OR vector(0)) / sum(rate(add_member_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error with add member',
          intervalFactor: 2,
        },
        threshold: 5,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error ratio of add member above 5%',
        noDataState: 'ok',
      },
      {
        title: 'Get Member Info Error Rate',
        custom: {
          name: 'get-member-info-error-rate',
          query: '(sum(rate(get_member_info_failed{namespace="production"}[10m])) OR vector(0)) / sum(rate(get_member_info_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error with get member info',
          intervalFactor: 2,
        },
        threshold: 5,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error ratio of get member info above 5%',
        noDataState: 'ok',
      },
      {
        title: 'Apply Benefit Error Rate',
        custom: {
          name: 'apply-benefit-error-rate',
          query: '(sum(rate(apply_benefit_failed{namespace="production"}[10m])) OR vector(0)) / sum(rate(apply_benefit_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error with apply benefit',
          intervalFactor: 2,
        },
        threshold: 5,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error ratio of apply benefit above 5%',
        noDataState: 'ok',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Loyalty Alerts',
  uid='loyalty_alerts',
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
