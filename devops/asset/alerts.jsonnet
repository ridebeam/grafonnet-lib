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

local alertDefinitions = [
  {
    row: 'APIs',
    alerts: [
      {
        title: 'Rate of HTTP 500s',
        custom: {
          query: target.ratio(
            metric='ktor_http_server_requests_seconds_count',
            filters=target.combineFilters(
              target.equalsFilter('service', 'asset'),
              target.equalsFilter('namespace', 'production'),
            ),
            numeratorFilters=target.likeFilter('status', '5..'),
            withServiceFilters=false,
            interval='2m',
          ).expr,
          alias: 'http 5xx rate',
        },
        format: 'percentunit',
        threshold: 0.3,
        message: 'Rate of errors increases above 30% of all requests',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Asset Alerts',
  uid='asset_alerts',
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
