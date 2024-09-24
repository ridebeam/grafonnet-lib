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

local rateOf5xxErrorMessage = 'Over 1% of requests are resulting in 5xx errors for last 5 minutes';
local rateOfBadDataErrorMessage = 'Rate of bad data in free bikes feed is over 1 count per second in last 5 minutes';
local rateOfInvalidTripDistanceMessage = 'Rate of invalid trip distance is high. Check mileage reporting of iot';

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Rate of Bad Vehicle Data Errors',
    alerts: [
      {
        title: '[External Data API] Rate of Bad Data Errors',
        counter: {
          name: 'external_data_api_vehicle_bad_data_total',
        },
        threshold: 0,
        message: rateOfBadDataErrorMessage,
        noDataState: 'ok',
      },
    ],
  },
  {
    row: 'Rate of Invalid Trip Distance',
    alerts: [
      {
        title: '[External Data API] Rate of Invalid Trip Distance',
        counter: {
          name: 'external-data-api_trip-invalid-distance',
        },
        threshold: 5,
        message: rateOfInvalidTripDistanceMessage,
        noDataState: 'ok',
      },
    ],
  },
  {
    row: 'Requests',
    alerts: [
      {
        title: '[External Data API] Percentage of Rate of 5XX Errors',
        custom: {
          name: 'pct-rate-of-5xx-errors-ratio-rate-of-requests',
          query: '((sum(rate(istio_requests_total{reporter="source", destination_service_name="external-data-api-http", destination_service_namespace="production", response_code=~"5.."}[2m])) OR vector(0)) / sum(rate(istio_requests_total{reporter="source", destination_service_name="external-data-api-http", destination_service_namespace="production"}[2m]))) * 100',
          alias: 'percentage rate of 5xx errors to rate of total requests',
        },
        threshold: 5,
        message: rateOf5xxErrorMessage,
      },
      {
        title: 'Rate of HTTP 400s',
        custom: {
          query: target.ratio(
            metric='istio_requests_total',
            filters=target.combineFilters(
              target.equalsFilter('reporter', 'source'), target.combineFilters(
                target.likeFilter('destination_service_name', 'external-data-api-http'),
                target.equalsFilter('destination_service_namespace', 'production'),
              ),
            ),
            numeratorFilters=target.combineFilters(
              target.likeFilter('response_code', '4.[012356789]'),
              target.notEqualFilter('response_code', '429'),
            ),
            withServiceFilters=false,
            interval='1m',
          ).expr,
          alias: 'http 4xx rate',
        },
        format: 'percentunit',
        threshold: 0.2,
        message: '',  // TODO message
      },
      {
        title: 'HTTP Endpoint Latency P95',
        timer: {
          name: 'istio_request_duration_milliseconds',
          filters: target.combineFilters(
            target.equalsFilter('reporter', 'source'), target.combineFilters(
              target.likeFilter('destination_service_name', 'external-data-api-http'),
              target.equalsFilter('destination_service_namespace', 'production'),
            ),
          ),
          percentile: 'p95',
        },
        format: 'ms',
        threshold: 5000,
        // query for last 2min to check if p95 is bigger than 10s, if yes and this lasts for 3min, we alert
        queryTimeStart: '2m',
        evaluateFor: '5m',
        // TODO message
        message: |||
          TODO
        |||,
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
    channels: alerts.notifications.opsEngineeringWarnings,
    evaluateFor: '5m',
    reducerType: 'min',
  },
  counters+: {
    filters: serviceFilter,
  },
}))
