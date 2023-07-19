local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local cloudwatch = grafana.cloudwatch;
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

local GB = 1024 * 1024 * 1204;

local alertDefaults = {
  format: 'short',
  channels: alerts.notifications.productionAlerts,
  thresholdType: 'gt',
  evaluateFor: '5m',
};

local gcpFilterMessaging = gcpTarget.equalsFilter('resource.label.container_name', 'messaging');
local messagingServiceFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'messaging'),
);

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Postgres',
    alerts: [
      {
        title: 'CDC Replication Lag (Critical)',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/postgresql/replication/replica_byte_lag',
          filters: gcpTarget.combineFilters(
            gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-beam-api'),
            gcpTarget.equalsFilter(l('replica_name'), 'PostgreSQL JDBC Driver'),
          ),
        },
        format: 'bytes',
        threshold: 10 * GB,
        message: '',  // TODO message
      },
      {
        title: 'CDC Replication Lag (Warning)',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/postgresql/replication/replica_byte_lag',
          filters: gcpTarget.combineFilters(
            gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-beam-api'),
            gcpTarget.equalsFilter(l('replica_name'), 'PostgreSQL JDBC Driver'),
          ),
        },
        format: 'bytes',
        threshold: 1 * GB,
        channels: alerts.notifications.productionWarnings,
        message: '',  // TODO message
      },
      {
        title: 'Analytics DB Replication Lag',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/postgresql/replication/replica_byte_lag',
          filters: gcpTarget.combineFilters(
            gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-beam-api'),
            gcpTarget.equalsFilter(l('replica_name'), 'ridebeam-core:replica-pg-asia-southeast1-beam-api-analytics'),
          ),
        },
        format: 'bytes',
        threshold: 1 * GB,
        message: '',  // TODO message
      },
      {
        title: 'Production DB CPU Usage (Critical)',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/cpu/utilization',
          filters: gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-beam-api'),
        },
        format: 'percentunit',
        threshold: 0.8,
        message: '',  // TODO message
      },
      {
        title: 'Production DB CPU Usage (Warning)',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/cpu/utilization',
          filters: gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-beam-api'),
        },
        format: 'percentunit',
        threshold: 0.6,
        channels: alerts.notifications.productionWarnings,
        message: '',  // TODO message
      },
      {
        title: 'Production DB Connections',
        gcpGauge: {
          name: 'cloudsql.googleapis.com/database/postgresql/num_backends',
          filters: gcpTarget.equalsFilter('resource.label.database_id', 'ridebeam-core:pg-asia-southeast1-beam-api'),
        },
        threshold: 800,
        message: '',  // TODO message
      },
    ],
  },
  {
    row: 'Redis',
    alerts: [
      {
        title: 'Memory Usage (Critical)',
        gcpGauge: {
          name: 'redis.googleapis.com/stats/memory/system_memory_usage_ratio',
          filters: gcpTarget.equalsFilter('resource.label.instance_id', 'projects/ridebeam-core/locations/asia-southeast1/instances/redis-asia-southeast1-beam-api'),
        },
        format: 'percentunit',
        threshold: 0.8,
        message: |||
          Production Redis free memory is low
          Please check about the issue and either:
          1. If there are a new large volume of vehicles registered recently
          2. clean up the leaking memory if it is due to memory leak
          3. upgrade the instance if it is due to data volume
          4. if this is a false alarm, please update the grafana alert config.

          P.S. the max memory available to use can be checked use `INFO` command after connect to Redis
          https://console.cloud.google.com/memorystore/redis/locations/asia-southeast1/instances/redis-asia-southeast1-beam-api/details?project=ridebeam-core
        |||,
      },
      {
        title: 'CPU Usage (Critical)',
        gcpGauge: {
          name: 'redis.googleapis.com/stats/cpu_utilization',
          filters: gcpTarget.equalsFilter('resource.label.instance_id', 'projects/ridebeam-core/locations/asia-southeast1/instances/redis-asia-southeast1-beam-api'),
          groupBys: ['metric.label.role'],
        },
        format: 'percent',
        threshold: 80,
        message: '',  // TODO message
      },
    ],
  },

  {
    row: 'API',
    alerts: [
      {
        title: 'Rate of HTTP 500s',
        custom: {
          query: target.ratio(
            metric='istio_requests_total',
            filters=target.combineFilters(
              target.equalsFilter('reporter', 'source'), target.combineFilters(
                target.likeFilter('destination_service_name', 'api.*'),
                target.equalsFilter('destination_service_namespace', 'production'),
              ),
            ),
            numeratorFilters=target.likeFilter('response_code', '5..'),
            withServiceFilters=false,
            interval='2m',
          ).expr,
          alias: 'http 5xx rate',
        },
        format: 'percentunit',
        threshold: 0.2,
        message: '',  // TODO message
      },
      {
        title: 'Rate of HTTP 400s',
        custom: {
          query: target.ratio(
            metric='istio_requests_total',
            filters=target.combineFilters(
              target.equalsFilter('reporter', 'source'), target.combineFilters(
                target.likeFilter('destination_service_name', 'api.*'),
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
              target.likeFilter('destination_service_name', 'api.*'),
              target.equalsFilter('destination_service_namespace', 'production'),
            ),
          ),
          percentile: 'p95',
        },
        format: 'ms',
        threshold: 10000,
        // query for last 2min to check if p95 is bigger than 10s, if yes and this lasts for 3min, we alert
        queryTimeStart: '2m',
        evaluateFor: '3m',
        // TODO message
        message: |||
          TODO
        |||,
      },
      {
        title: 'Kafka: vehicle-event consumption lag',
        timer: {
          name: 'kafka-consume-lag',
          filters: target.combineFilters(
            messagingServiceFilter,
            target.equalsFilter('kafka_source_topic', 'vehicle-event'),
          ),
          percentile: 'p95',
        },
        format: 's',
        threshold: 120,
        queryTimeStart: '2m',
        evaluateFor: '20m',
        message: 'https://beammobility.atlassian.net/l/cp/qNHQGAqr',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts',
  uid='api_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
  },
  gcpGauges+: {
    gcpHelpers: gcpHelpers,
  },
}))
