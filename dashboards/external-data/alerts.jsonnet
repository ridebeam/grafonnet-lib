local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'external-data-api'),
);

local msg = 'Over 1% of requests are resulting in 5xx errors for last 5 minutes';

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: '5XX Errors',
    alerts: [
      {
        title: '[External Data API] Percentage of Rate of 5XX Errors',
        custom: {
          name: 'rate-of-5xx-errors-ratio-rate-of-requests',
          query: '((sum(rate(istio_requests_total{reporter="source", destination_service_name="external-data-api-http", destination_service_namespace="production", response_code=~"5.."}[$__interval])) OR vector(0)) / sum(rate(istio_requests_total{reporter="source", destination_service_name="external-data-api-http", destination_service_namespace="production"}[$__interval]))) * 100',
          alias: 'rate of 5xx errors to rate of total requests',
        },
        threshold: 1,
        message: msg,
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'External Data API Alerts',
  uid='external-data-api_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: alerts.notifications.opsGRAlerts,
    evaluateFor: '5m',
    reducerType: 'min',
  },
  counters+: {
    filters: serviceFilter,
  },
}))
