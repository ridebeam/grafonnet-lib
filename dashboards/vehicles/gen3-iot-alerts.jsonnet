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
local filterGen3IoT = target.equalsFilter('manufacturer', 'omnigen3');
local globalFilter = target.combineFilters(filterIotServer, filterGen3IoT);

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'system-errors',
    alerts: [
      {
        title: 'ecu lock unlock error',
        counter: {
          name: 'action-error',
          filters: target.combineFilters(
            globalFilter,
            target.equalsFilter('state', 'ecuLock'),
          ),
        },
        format: 's',
        threshold: 10,
        message: |||
          Seeing gen3 IoT ecuLock error
        |||,
      },
      
      {
        title: 'battery unlock error',
        counter: {
          name: 'action-error',
          filters: target.combineFilters(
            globalFilter,
            target.equalsFilter('state', 'batteryLock'),
          ),
        },
        format: 's',
        threshold: 10,
        message: |||
          Seeing gen3 IoT battery unlock error
        |||,
      },


      {
        title: 'helmet lock unlock error',
        counter: {
          name: 'action-error',
          filters: target.combineFilters(
            globalFilter,
            target.equalsFilter('state', 'helmetLock'),
          ),
        },
        format: 's',
        threshold: 10,
        message: |||
          Seeing gen3 IoT helmet lock error
        |||,
      },


      {
        title: 'iot error code report count',
        counter: {
          name: 'error-report',
          filters: globalFilter,
        },
        format: 's',
        threshold: 100,
        message: |||
          Seeing high volume of iot error codes
        |||,
      },


      {
        title: 'alarm count',
        counter: {
          name: 'alarm-report',
          filters: globalFilter,
        },
        format: 's',
        threshold: 100,
        message: |||
          Seeing gen3 IoT alarm report exceeds threshold
        |||,
      },


      {
        title: 'disconnection count',
        counter: {
          name: 'disconnection',
          filters: globalFilter,
        },
        format: 's',
        threshold: 100,
        message: |||
          Seeing gen3 IoT disconnection count exceeds threshold
        |||,
      },


      {
        title: 'ecu lock unlock delay',
        timer: {
          name: 'unlock-via-power-control-duration',
          filters: globalFilter,
        },
        format: 's',
        threshold: 5,
        message: |||
          Seeing gen3 IoT ecu lock unlock timing exceeds threshold
        |||,
      },


      {
        title: 'helmet lock delay',
        timer: {
          name: 'helmet-lock-timing',
          filters: globalFilter,
        },
        format: 's',
        threshold: 5,
        message: |||
          Seeing gen3 IoT helmet lock timing exceeds threshold
        |||,
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Gen3 IoT Release Alerts',
  uid='gen3_iot_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slack],
  },
}))
