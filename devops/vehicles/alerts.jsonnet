local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local filterIotServer = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'iot-server'),
);
local filterVehicleController = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'vehicle-controller'),
);
local filterVehicleGateway = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'vehicle-gateway'),
);

local filterGen3IoT = target.equalsFilter('manufacturer', 'omnigen3');

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
            filterIotServer,
            target.equalsFilter('kafka_source_topic', 'vehicle-action'),
          ),
        },
        format: 's',
        threshold: 60,
        // TODO message
        message: |||
          TODO
        |||,
      },
      {
        title: 'kafka consumption rate: vehicle-action',
        counter: {
          name: 'kafka-consume',
          filters: target.combineFilters(
            filterIotServer,
            target.equalsFilter('kafka_source_topic', 'vehicle-action'),
          ),
        },
        threshold: 1,
        thresholdType: 'lt',
        // TODO message
        message: |||
          TODO
        |||,
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
            filterVehicleController,
            target.equalsFilter('kafka_source_topic', 'vehicle-state'),
          ),
        },
        format: 's',
        threshold: 60,
        // TODO message
        message: |||
          TODO
        |||,
      },
      {
        title: 'kafka consumption rate: vehicle-state',
        counter: {
          name: 'kafka-consume',
          filters: target.combineFilters(
            filterVehicleController,
            target.equalsFilter('kafka_source_topic', 'vehicle-state'),
          ),
        },
        threshold: 1,
        thresholdType: 'lt',
        // TODO message
        message: |||
          TODO
        |||,
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
            histogram_quantile(0.95, sum(rate(kafka_consume_lag_bucket{namespace="production",service="vehicle-gateway", kafka_source_topic="vehicle-event"}[1m])) by (pod_name, le))
            * group(grpc_io_server_completed_rpcs{namespace="production", service="vehicle-gateway"}) by (pod_name)
          |||,
          alias: '{{pod_name}}',
        },
        format: 's',
        threshold: 60,
        // TODO message
        message: |||
          TODO
        |||,
      },
      {
        title: 'kafka consumption rate: vehicle-event',
        counter: {
          name: 'kafka-consume',
          filters: target.combineFilters(
            filterVehicleGateway,
            target.equalsFilter('kafka_source_topic', 'vehicle-event'),
          ),
        },
        threshold: 1,
        thresholdType: 'lt',
        // TODO message
        message: |||
          TODO
        |||,
      },
    ],
  },
];

local disconnectedVehicleAlerts = [
 {
    row: 'vehicle-watchdog',
    alerts: [
      {
        title: 'number of deployed and disconnected vehicles by city',
        custom: {
          name: 'vehicle_deployed_disconnected',
          query: |||
            avg by(city_id) (vehicle_deployed_disconnected{namespace="production", service="vehicle-watchdog"}) > 0
          |||,
          alias: '{{city_id}}',
        },
        threshold: 300,
        thresholdType: 'gt',
        message: 'A lot of disconnected vehicle! A lot of disconnected vehicles! <https://grafana.devops.ridebeam.cloud/d/vehicles_alerts/vehicle-alerts?orgId=1&from=now-30m&to=now-1m|Go to dashboard>',
      }
    ]
  }
];

local warningAlerts = [
  {
    row: 'warnings',
    alerts: [
      {
        title: 'invalid-mileage',
        counter: {
          name: 'invalid-mileage-value',
          filters: filterIotServer,
        },
        threshold: 2,
        thresholdType: 'gt',
        message: |||
          Vehicles with invalid mileage rising more than expected
        |||,
        noDataState: 'ok',
      },
      {
        title: 'error-throttle-off',
        counter: {
          name: 'action-error',
          filters: target.combineFilters(
            filterIotServer,
            target.equalsFilter('state', 'throttle'),
          ),
        },
        threshold: 3,
        thresholdType: 'gt',
        message: |||
          Error when trying to toggle throttle state
        |||,
        noDataState: 'ok',
      },
      {
        title: 'vehicle-throttle-in-ops-zone',
        counter: {
          name: 'vehicle-throttle-in-ops-zone',
          filters: filterVehicleController,
        },
        threshold: 3,
        thresholdType: 'gt',
        message: |||
          Vehicle with throttle off in ops zone
        |||,
        noDataState: 'ok',
      },
      {
        title: 'unlock failed per model',
        custom: {
          name: 'unlock-failed-per-model',
          // skipping okai & yadea since we have so much anomalies for those vehicle
          query: |||
            sum(rate(start_trip_error{namespace="production", vehicle_model!="OKAI_EB100", vehicle_model!="YADEA_Q20", vehicle_model!=""}[30m])) by (vehicle_model) / sum(rate(start_trip{namespace="production", vehicle_model!="OKAI_EB100", vehicle_model!="YADEA_Q20", vehicle_model!=""}[30m])) by (vehicle_model)
          |||,
          alias: '{{vehicle_model}}',
        },
        threshold: 0.3,
        thresholdType: 'gt',
        message: |||
          Unlock error rate spikes
        |||,
      },
      {
        title: 'iot-server kafka vehicle-action consume instance count',
        custom: {
          name: 'iot-server kafka vehicle-action consume instance count',
          query: |||
            count(histogram_quantile(0.99, sum(rate(kafka_consume_lag_bucket{namespace="production", service="iot-server", kafka_source_topic="vehicle-action"}[1m])) by (le,pod_name)))
          |||,
          alias: 'count',
        },
        thresholdType: 'lt',
        threshold: 3.5,
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
  'Vehicle Alerts',
  uid='vehicles_alerts',
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
      channels: alerts.notifications.vehiclesAlerts,
    },
  })
)
.addRows(
  alerts.createRows(disconnectedVehicleAlerts, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.iotConnectivityAlerts,
    },
  })
)
.addRows(
  alerts.createRows(warningAlerts, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.productionWarnings,
    },
  })
)
