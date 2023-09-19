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
        title: 'Register/Login(without phone number) With Google Error Rate',
        custom: {
          name: 'register-with-google-error-rate',
          query: '((sum(rate(register_with_google_failed{namespace="production"}[10m])) OR vector(0)) - (sum(rate(login_with_google_send_otp_failed{namespace="production"}[10m])) OR vector(0))) / sum(rate(register_with_google_attempt{namespace="production"}[10m]) > 0) * 100',
          alias: 'error register/login with google',
          intervalFactor: 2,
        },
        threshold: 5,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of register/login with google above 5%',
        noDataState: 'ok',
      },
      {
        title: 'Login With Google With Linked Phone Number Error Rate',
        custom: {
          name: 'register-with-google-with-linked-phone-number-error-rate',
          query: '(sum(rate(login_with_google_send_otp_failed{namespace="production"}[60m])) OR vector(0)) / sum(rate(register_with_google_attempt{namespace="production"}[60m]) > 0) * 100',
          alias: 'error login with google with linked phone number',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of login with google with linked phone number above 20%',
        noDataState: 'ok',
      },
      {
        title: 'Register/Login(without phone number) With Apple Error Rate',
        custom: {
          name: 'register-with-apple-error-rate',
          query: '((sum(rate(register_with_apple_failed{namespace="production"}[60m])) OR vector(0)) - (sum(rate(login_with_apple_send_otp_failed{namespace="production"}[60m])) OR vector(0))) / sum(rate(register_with_apple_attempt{namespace="production"}[60m]) > 0) * 100',
          alias: 'error register/login with apple',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of register/login with apple above 20%',
        noDataState: 'ok',
      },
      {
        title: 'Login With Apple With Linked Phone Number Error Rate',
        custom: {
          name: 'register-with-apple-with-linked-phone-number-error-rate',
          query: '(sum(rate(login_with_apple_send_otp_failed{namespace="production"}[60m])) OR vector(0)) / sum(rate(register_with_apple_attempt{namespace="production"}[60m]) > 0) * 100',
          alias: 'error login with apple with linked phone number',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of login with apple with linked phone number above 20%',
        noDataState: 'ok',
      },
      {
        title: 'Register/Login(without phone number) With Kakao Error Rate',
        custom: {
          name: 'register-with-kakao-error-rate',
          query: '((sum(rate(register_with_kakao_failed{namespace="production"}[60m])) OR vector(0)) - (sum(rate(login_with_kakao_send_otp_failed{namespace="production"}[60m])) OR vector(0))) / sum(rate(register_with_kakao_attempt{namespace="production"}[60m]) > 0) * 100',
          alias: 'error register/login with kakao',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of register/login with kakao above 20%',
        noDataState: 'ok',
      },
      {
        title: 'Login With kakao With Linked Phone Number Error Rate',
        custom: {
          name: 'register-with-kakao-with-linked-phone-number-error-rate',
          query: '(sum(rate(login_with_kakao_send_otp_failed{namespace="production"}[60m])) OR vector(0)) / sum(rate(register_with_kakao_attempt{namespace="production"}[60m]) > 0) * 100',
          alias: 'error login with kakao with linked phone number',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of login with kakao with linked phone number above 20%',
        noDataState: 'ok',
      },
      {
        title: 'Login With Phone Number Error Rate',
        custom: {
          name: 'login-with-phone-number-error-rate',
          query: '((sum(rate(login_with_phone_number_failed{namespace="production"}[60m])) OR vector(0)) - (sum(rate(login_with_phone_number_failed_not_registered_user{namespace="production"}[60m])) OR vector(0))) / sum(rate(login_with_phone_number_attempt{namespace="production"}[60m]) > 0) * 100',
          alias: 'error login with phone number',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of login with phone number above 20%',
        noDataState: 'ok',
      },
      {
        title: 'User Not Found When Login Phone Number Error Rate',
        custom: {
          name: 'not-found-user-when-login-phone-number-error-rate',
          query: '(sum(rate(login_with_phone_number_failed_not_registered_user{namespace="production"}[6h])) OR vector(0)) / sum(rate(login_with_phone_number_attempt{namespace="production"}[6h]) > 0) * 100',
          alias: 'error user not found when login with phone number',
          intervalFactor: 2,
        },
        threshold: 90,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of user not found when login with phone number above 90%',
        noDataState: 'ok',
      },
      {
        title: 'Verify Otp Error Rate',
        custom: {
          name: 'verify-otp-error-rate',
          query: '(sum(rate(verify_otp_failed{namespace="production"}[120m])) OR vector(0)) / sum(rate(verify_otp_attempt{namespace="production"}[120m]) > 0) * 100',
          alias: 'error verifying otp',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        queryTimeStart: '10m',
        message: 'Error ratio of verifying otp is above 20%',
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
      channels: alerts.notifications.productionWarnings,
      reducerType: 'avg',
    },
  },)
)
