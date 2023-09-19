local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';

local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;

local envFilter = target.equalsFilter('namespace', 'staging');

local iotServerServiceFilter = target.equalsFilter('service', 'iot-server');
local vehicleControllerServiceFilter = target.equalsFilter('service', 'vehicle-controller');
local vehicleGatewayServiceFilter = target.equalsFilter('service', 'vehicle-gateway');
local messagingServiceFilter = target.equalsFilter('service', 'messaging');

local iotServerFilter = target.combineFilters(
  envFilter,
  iotServerServiceFilter,
);
local vehicleControllerFilter = target.combineFilters(
  envFilter,
  vehicleControllerServiceFilter,
);
local vehicleGatewayFilter = target.combineFilters(
  envFilter,
  vehicleGatewayServiceFilter,
);
local messagingFilter = target.combineFilters(
  envFilter,
  messagingServiceFilter,
);

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'iot-server',
    alerts: [
      {
        title: 'kafka consumption lag: vehicle-action',
        timer: {
          name: 'kafka-consume-lag',
          filters: target.combineFilters(
            iotServerFilter,
            target.equalsFilter('kafka_source_topic', 'vehicle-action'),
          ),
        },
        format: 's',
        threshold: 60,
        message: 'TODO',
      },
    ],
  },
  {
    row: 'vehicle-controller',
    alerts: [
      {
        title: 'kafka consumption lag: vehicle-state',
        timer: {
          name: 'kafka-consume-lag',
          filters: target.combineFilters(
            vehicleControllerFilter,
            target.equalsFilter('kafka_source_topic', 'vehicle-state'),
          ),
        },
        format: 's',
        threshold: 60,
        message: 'TODO',
      },
      {
        title: 'kafka consumption rate: vehicle-state',
        counter: {
          name: 'kafka-consume',
          filters: target.combineFilters(
            vehicleControllerFilter,
            target.equalsFilter('kafka_source_topic', 'vehicle-state'),
          ),
        },
        threshold: 1,
        thresholdType: 'lt',
        message: 'TODO',
      },
    ],
  },
  {
    row: 'vehicle-gateway',
    alerts: [
      {
        title: 'kafka consumption lag: vehicle-event (serving instances only)',
        custom: {
          name: 'kafka-consume-lag',
          query: |||
            histogram_quantile(0.95, sum(rate(kafka_consume_lag_bucket{namespace="stable",service="vehicle-gateway", kafka_source_topic="vehicle-event"}[1m])) by (pod_name, le))
            * group(grpc_io_server_completed_rpcs{namespace="stable", service="vehicle-gateway"}) by (pod_name)
          |||,
          alias: '{{pod_name}}',
        },
        format: 's',
        threshold: 60,
        message: 'TODO',
      },
      {
        title: 'kafka consumption rate: vehicle-event',
        counter: {
          name: 'kafka-consume',
          filters: target.combineFilters(
            vehicleGatewayFilter,
            target.equalsFilter('kafka_source_topic', 'vehicle-event'),
          ),
        },
        threshold: 1,
        thresholdType: 'lt',
        message: 'TODO',
      },
    ],
  },
  {
    row: 'beam-api',
    alerts: [
      {
        title: 'Kafka: vehicle-event consumption lag',
        timer: {
          name: 'kafka-consume-lag',
          filters: target.combineFilters(
            messagingFilter,
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
  'Vehicle Alerts Staging',
  uid='vehicles_alerts_staging',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(
  alerts.createRows(alertDefinitions, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.vehiclesWarning,
    },
  })
)
