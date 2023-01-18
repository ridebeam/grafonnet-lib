local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local filterService = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'user-profile'),
);

local alertDefs = [
  {
    row: 'Error Rate',
    alerts: [
      {
        title: 'Register/Login With Google Error Rate',
        custom: {
          name: 'register-with-google-error-rate',
          query: '(sum(rate(register_with_google_failed{namespace="production"}[10m])) OR vector(0)) / sum(rate(register_with_google_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error with register/login with google',
          intervalFactor: 2,
        },
        threshold: 5,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error ratio of register/login with google above 5%',
        noDataState: 'ok',
      },
      {
        title: 'Register/Login With Apple Error Rate',
        custom: {
          name: 'register-with-apple-error-rate',
          query: '(sum(rate(register_with_apple_failed{namespace="production"}[10m])) OR vector(0)) / sum(rate(register_with_apple_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error with register/login with apple',
          intervalFactor: 2,
        },
        threshold: 5,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error ratio of register/login with apple above 5%',
        noDataState: 'ok',
      },
      {
        title: 'Login With Phone Number Error Rate',
        custom: {
          name: 'login-with-phone-number-error-rate',
          query: '((sum(rate(login_with_phone_number_failed{namespace="production"}[10m])) OR vector(0)) - (sum(rate(login_with_phone_number_failed_not_registered_user{namespace="production"}[10m]))) OR vector(0)) / sum(rate(login_with_phone_number_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error with login with phone number',
          intervalFactor: 2,
        },
        threshold: 10,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error ratio of login with phone number above 10%',
        noDataState: 'ok',
      },
      {
        title: 'Verify Otp Error Rate',
        custom: {
          name: 'verify-otp-error-rate',
          query: '(sum(rate(verify_otp_failed{namespace="production"}[10m])) OR vector(0)) / sum(rate(verify_otp_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error with verifying otp',
          intervalFactor: 2,
        },
        threshold: 5,
        thresholdType: 'gt',
        queryTimeStart: '15m',
        message: 'Error ratio of verifying otp is above 5%',
        noDataState: 'ok',
      },
    ],
  },
];

grafana.dashboard.new(
  'User-profile production alerts',
  uid='user_profle_alerts',
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