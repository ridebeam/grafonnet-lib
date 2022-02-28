local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local gcp = import '../../helper/gcp.libsonnet';
local gcpHelpers = gcp.init('ridebeam-core');
local gcpTarget = gcpHelpers.target;
local gcpPanel = gcpHelpers.panel;
local m = gcpTarget.customMetric;
local l = gcpTarget.label;

local env = 'production';
local service = 'settings-lookup';

// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', env),
  target.equalsFilter('service', service),
);

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Kafka Lag > 200 ms',
    alerts: [
      {
        title: 'kafka lag settings.georegions',
        timer: {
          name: 'kafka-consume-lag',
          groupBys: ['kafka_source_topic'],
          filters: target.combineFilters(
            serviceFilter,
            target.equalsFilter('kafka_source_topic', 'settings.georegions'),
          ),
        },
        threshold: 1500,
        evaluateFor: '1m',
        message: 'Reading problems',
      },
      {
        title: 'kafka lag settings.patches',
        timer: {
          name: 'kafka-consume-lag',
          groupBys: ['kafka_source_topic'],
          filters: target.combineFilters(
            serviceFilter,
            target.equalsFilter('kafka_source_topic', 'settings.patches'),
          ),
        },
        threshold: 1500,
        evaluateFor: '1m',
        message: 'Reading problems',
      },
    ],
  },
  {
    row: 'Kafka consume',
    alerts: [
      {
        title: 'kafka consume settings.georegions',
        counter: {
          name: 'kafka-consume',
          groupBys: ['kafka_source_topic'],
          filters: target.combineFilters(
            serviceFilter,
            target.equalsFilter('kafka_source_topic', 'settings.georegions'),
          ),
        },
        threshold: 0,
        thresholdType: 'lt',
        evaluateFor: '60m',
        message: 'Cache are not up to date',
      },
      {
        title: 'kafka consume settings.patches',
        counter: {
          name: 'kafka-consume',
          groupBys: ['kafka_source_topic'],
          filters: target.combineFilters(
            serviceFilter,
            target.equalsFilter('kafka_source_topic', 'settings.patches'),
          ),
        },
        threshold: 0,
        thresholdType: 'lt',
        evaluateFor: '60m',
        message: 'Cache are not up to date',
      },
    ],
  },
  {
    row: 'Lookup Response time',
    alerts: [
      {
        title: 'Settings Lookup p95 Latency',
        custom: {
          name: 'p95 Latency ${grpc_server_method}',
          query: |||
            histogram_quantile(0.95, sum(rate(grpc_io_server_server_latency_bucket{namespace="%(env)s", service="%(service)s"}[1m])) by (le, grpc_server_method))
          ||| % { env: env, service: service },
          alias: '{{grpc_server_method}}',
        },
        threshold: 50000,
        format: 'ms',
        message: 'p95 latency is greater than 200ms in the last 5 minutes. ',
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Dev Alerts',
  uid='settings_staging',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slackSettings],
  },
}))
