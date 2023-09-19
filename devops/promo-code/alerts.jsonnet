local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local filterService = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'promo-code'),
);

local alertDefs = [
  {
    row: 'Error Rate',
    alerts: [
      {
        title: 'Claim Promo Code Error Rate',
        custom: {
          name: 'claim-promo-code-error-rate',
          query: '(sum(rate(promo_code_claim_failed_total{namespace="production"}[10m]) OR vector(0))) / sum(rate(promo_code_claim_attempt_total{namespace="production"}[10m]) > 0) * 100',
          alias: 'error claiming promo code',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error rate for claiming promo code is above 20%',
        noDataState: 'ok',
      },
      {
        title: 'Get Claimable Promo Code Error Rate',
        custom: {
          name: 'get-claimable-promo-code-error-rate',
          query: '(sum(rate(promo_code_get_claimable_failed_total{namespace="production"}[10m]) OR vector(0))) / sum(rate(promo_code_get_claimable_attempt_total{namespace="production"}[10m]) > 0) * 100',
          alias: 'error getting claimable promo code',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error rate for getting claimable promo code is above 10%',
        noDataState: 'ok',
      },
      {
        title: 'Get Claimed Promo Code Error Rate',
        custom: {
          name: 'get-claimed-promo-code-error-rate',
          query: '(sum(rate(promo_code_get_claimed_failed_total{namespace="production"}[10m]) OR vector(0))) / sum(rate(promo_code_get_claimed_attempt_total{namespace="production"}[10m]) > 0) * 100',
          alias: 'error getting claimed promo code',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error rate for getting claimed promo code is above 10%',
        noDataState: 'ok',
      },
      {
        title: 'Get Past Promo Code Error Rate',
        custom: {
          name: 'get-past-promo-code-error-rate',
          query: '(sum(rate(promo_code_get_past_failed_total{namespace="production"}[10m]) OR vector(0))) / sum(rate(promo_code_get_past_attempt_total{namespace="production"}[10m]) > 0) * 100',
          alias: 'error getting past promo code',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error rate for getting past promo code is above 10%',
        noDataState: 'ok',
      },
    ],
  },
];

grafana.dashboard.new(
  'Promo Code Production Alerts',
  uid='promo_code_production_alerts',
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
      channels: alerts.notifications.slackAlertsOnly,
      reducerType: 'avg',
    },
  },)
)
