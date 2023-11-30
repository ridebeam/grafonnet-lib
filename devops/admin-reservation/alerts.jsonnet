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

local serviceFilter = target.combineFilters(
  target.equalsFilter('service', 'admin-reservation'),
  target.equalsFilter('namespace', 'production'),
);

local adminReservationServiceAlerts = [
  {
    row: 'Rate of Bad Http Responses',
    alerts: [
      {
        title: 'Rate of HTTP 5xx',
        custom: {
          query: target.ratio(
            metric='ktor_http_server_requests_seconds_count',
            filters=serviceFilter,
            numeratorFilters=target.likeFilter('status', '5..'),
            withServiceFilters=false,
            interval='30m',
          ).expr,
          alias: 'http 5xx rate',
        },
        format: 'percentunit',
        threshold: 0.0003,
        message: 'Rate of 5xx responses increases above 0.03% of all requests',
      },
      {
        title: 'Rate of HTTP 4xx',
        custom: {
          query: target.ratio(
            metric='ktor_http_server_requests_seconds_count',
            filters=serviceFilter,
            numeratorFilters=target.likeFilter('status', '4..'),
            withServiceFilters=false,
            interval='30m',
          ).expr,
          alias: 'http 4xx rate',
        },
        format: 'percentunit',
        threshold: 0.2,
        message: 'Rate of 4xx responses increases above 20% of all requests',
      },
    ],
  },
];

local adminReservationClientAlerts = [
  {
    row: 'Rate of Bad Http Responses (client)',
    alerts: [
      {
        title: 'Get Reservations Errors',
        custom: {
          name: 'rate-of-failure-ratio-get-reservations',
          query: '((sum(rate(get-reservations-failure{namespace="production"}[30m])) OR vector(0)) / sum(rate(get-reservations-atttempts{namespace="production"}[30m])))',
          alias: 'rate of failure ratio get reservations',
        },
        threshold: 0.2,
        message: 'Rate of errors of get reservations increases above 20% of all requests',
      },
      {
        title: 'Create Reservation Errors',
        custom: {
          name: 'rate-of-failure-ratio-create-reservation',
          query: '((sum(rate(create-reservation-failure{namespace="production"}[30m])) OR vector(0)) / sum(rate(create-reservation-attempts{namespace="production"}[30m])))',
          alias: 'rate of failure ratio create reservation',
        },
        threshold: 0.2,
        message: 'Rate of errors of create reservation increases above 20% of all requests',
      },
         {
        title: 'Redeem Reservation Errors',
        custom: {
          name: 'rate-of-failure-ratio-create-reservation',
          query: '((sum(rate(redeem-reservation-failure{namespace="production"}[30m])) OR vector(0)) / sum(rate(redeem-reservation-attempts{namespace="production"}[30m])))',
          alias: 'rate of failure ratio redeem reservation',
        },
        threshold: 0.2,
        message: 'Rate of errors of redeem reservation increases above 20% of all requests',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Admin Reservation Alerts',
  uid='admin_reservation_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(adminReservationServiceAlerts, alerts.defaults {
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
.addRows(alerts.createRows(adminReservationClientAlerts, alerts.defaults {
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