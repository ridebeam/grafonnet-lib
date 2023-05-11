local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local filterService = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'beam-for-business'),
);

local alertDefs = [
  {
    row: 'Error Rate',
    alerts: [
      {
        title: 'Create Business Profile Error Rate',
        custom: {
          name: 'create-business-profile-error-rate',
          query: '(sum(rate(business_profile_create_failed_total{namespace="production"}[10m]) OR vector(0))) / sum(rate(business_profile_create_request_total{namespace="production"}[10m]) > 0) * 100',
          alias: 'error creating business profile',
          intervalFactor: 2,
        },
        threshold: 30,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error rate of create business profile is above 30%',
        noDataState: 'ok',
      },
      {
        title: 'Delete Business User Error Rate',
        custom: {
          name: 'delete-business-user-error-rate',
          query: '(sum(rate(delete_business_user_failed_total{namespace="production"}[10m]) OR vector(0))) / sum(rate(delete_business_user_attempt_total{namespace="production"}[10m]) > 0) * 100',
          alias: 'error deleting business user',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error rate for deleting business user is above 10%',
        noDataState: 'ok',
      },
      {
        title: 'Redeem Business User Error Rate',
        custom: {
          name: 'activation-code-redeem-error-rate',
          query: '(sum(rate(activation_code_redeem_failed_total{namespace="production"}[10m]) OR vector(0))) / sum(rate(activation_code_redeem_attempt_total{namespace="production"}[10m]) > 0) * 100',
          alias: 'error activating code',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error rate for redeeming activating code is above 10%',
        noDataState: 'ok',
      },
    ],
  },
];

grafana.dashboard.new(
  'Beam For Business Production Alerts',
  uid='beam_for_business_production_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(
  alerts.createRows(alertDefs, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.test,
      reducerType: 'avg',
    },
  },)
)
