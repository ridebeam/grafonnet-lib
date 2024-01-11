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
        custom: {
          query: '( sum(delta(bad_franchise_service_response{namespace="production"}[1m])) / sum(delta(total_franchise_requests{namespace="production"}[1m])) ) * 100',
          alias: 'bad franchise service response rate',
        },
        threshold: 30,
        message: '5xx responses from franchise service are > 30% of all requests to the franchise service.'
      },
      {
        title: 'Failure to forward request to franchise service',
        custom: {
          query: '( sum(delta(failed-to-forward-franchise-request{namespace="production"}[1m])) / sum(delta(total_franchise_requests{namespace="production"}[1m])) ) * 100',
          alias: 'failed to forward franchise request rate',
        },
        threshold: 30,
        message: 'Bff-Dashboard requests failing to forward to franchise service are > 30% of all requests to the franchise service.'
      }
    ]
  },
];

local heapMemoryFranchiseAlerts = [
  {
    row: 'Memory Usage of Franchise Service',
    alerts: [
      {
        title: 'High heap memory usage',
        custom: {
          query: '( sum(avg_over_time(jvm_memory_used_bytes{area="heap", namespace="production", service="franchise"}[1m])) by (pod_name) * 100 ) / ( sum(avg_over_time(jvm_memory_max_bytes{area="heap", namespace="production", service="franchise"}[1m]))by(application, pod_name) )',
          alias: 'high heap memory usage',
        },
        threshold: 60,
        message: 'Franchise total heap memory usage is > 60%'
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
  }
}))
.addRows(alerts.createRows(heapMemoryFranchiseAlerts, alerts.defaults {
  alerts+: {
    channels: alerts.notifications.opsEngineeringWarnings,
    evaluateFor: '5m',
    reducerType: 'max',
    noDataState: 'ok',
  }
}))
