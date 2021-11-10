local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local alertDefaults = {
  format: 'short',
  channels: alerts.notifications.test,
  thresholdType: 'gt',
  evaluateFor: '5m',
};

local filterIotServer = target.equalsFilter('service', 'iot-server');
local filterVehicleController = target.equalsFilter('service', 'vehicle-controller');
local filterVehicleGateway = target.equalsFilter('service', 'vehicle-gateway');

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
        title: 'kafka consumption lag: vehicle-event',
        timer: {
          name: 'kafka-consume-lag',
          filters: target.combineFilters(
            filterVehicleGateway,
            target.equalsFilter('kafka_source_topic', 'vehicle-event'),
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

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts',
  uid='vehicles_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions))
