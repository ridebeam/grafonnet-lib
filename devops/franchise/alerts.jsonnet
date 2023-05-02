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
  target.equalsFilter('service', 'franchise'),
  target.equalsFilter('namespace', 'production'),
);

local franchiseServiceAlerts = [
  {
    row: 'Rate of Bad Http Responses',
    alerts: [
      {
        title: 'Rate of HTTP 500s',
        custom: {
          query: target.ratio(
            metric='ktor_http_server_requests_seconds_count',
            filters=serviceFilter,
            numeratorFilters=target.likeFilter('status', '5..'),
            withServiceFilters=false,
            interval='2m',
          ).expr,
          alias: 'http 5xx rate',
        },
        format: 'percentunit',
        threshold: 0.3,
        message: 'Rate of 5xx responses increases above 30% of all requests',
      },
      {
        title: 'Rate of HTTP 400s',
        custom: {
          query: target.ratio(
            metric='ktor_http_server_requests_seconds_count',
            filters=serviceFilter,
            numeratorFilters=target.likeFilter('status', '4..'),
            withServiceFilters=false,
            interval='2m',
          ).expr,
          alias: 'http 4xx rate',
        },
        format: 'percentunit',
        threshold: 0.3,
        message: 'Rate of 4xx responses increases above 30% of all requests',
      },
    ],
  },
];

local bffDashboardFranchiseAlerts = [
  {
    row: 'Bff-Dashboard to Franchise Service',
    alerts: [
      {
        title: 'Bad response from franchise service',
        counter: {name: 'bad-franchise-service-response'},
        threshold: 15,
        message: 'Franchise service is responding with 4xx/5xx error codes.'
      },
      {
        title: 'Failure to forward request to franchise service',
        counter: {name: 'failed-to-forward-franchise-request'},
        threshold: 5,
        message: 'Bff-Dashboard is failing to forward requests to franchise service.'
      }
    ]
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Franchise Alerts',
  uid='franchise_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(franchiseServiceAlerts, alerts.defaults {
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
.addRows(alerts.createRows(bffDashboardFranchiseAlerts, alerts.defaults {
  alerts+: {
    channels: alerts.notifications.opsEngineeringWarnings,
    evaluateFor: '5m',
    reducerType: 'max',
    noDataState: 'ok',
  },
  counters+: {
    func: 'delta',
    filters: target.equalsFilter('namespace', 'production'),
  },
}))