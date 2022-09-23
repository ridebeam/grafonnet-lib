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
local filterVehicleWatchdog = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'vehicle-watchdog'),
);

local filterDeployedVehicle = target.likeFilter('vehicle_status', 'rider|standby');
local filterMMX = target.equalsFilter('vehicle_model', 'NINEBOT_MODEL_MAX_PLUS_X');

local globalFilter = target.combineFilterArray([filterIotServer, filterMMX, filterDeployedVehicle]);


local alertDefaults = {
  format: 'short',
  channels: alerts.notifications.productionAlerts,
  thresholdType: 'gt',
  evaluateFor: '5m',
};

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
        threshold: 3,
        noDataState: 'ok',
        message: |||
          Seeing MMX ecuLock error
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
        threshold: 1,
        noDataState: 'ok',
        message: |||
          Seeing MMX battery unlock error
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
        threshold: 3,
        noDataState: 'ok',
        message: |||
          Seeing MMX helmet lock error
        |||,
      },


      {
        title: 'iot error code report count',
        counter: {
          name: 'error-report',
          filters: globalFilter,
        },
        threshold: 3,
        noDataState: 'ok',
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
        threshold: 3,
        noDataState: 'ok',
        message: |||
          Seeing MMX alarm report exceeds threshold
        |||,
      },


      {
        title: 'disconnection count',
        counter: {
          name: 'disconnection',
          filters: globalFilter,
        },
        threshold: 5,
        noDataState: 'ok',
        message: |||
          Seeing MMX disconnection count exceeds threshold
        |||,
      },


      {
        title: 'ecu lock unlock delay',
        timer: {
          name: 'unlock-via-power-control-duration',
          filters: globalFilter,
        },
        format: 's',
        threshold: 15,
        noDataState: 'ok',
        message: |||
          Seeing MMX ecu lock unlock timing exceeds threshold
        |||,
      },


      {
        title: 'helmet lock delay',
        timer: {
          name: 'helmet-lock-timing',
          filters: globalFilter,
        },
        format: 's',
        threshold: 15,
        noDataState: 'ok',
        message: |||
          Seeing MMX helmet lock timing exceeds threshold
        |||,
      },

      
    ],
  },

  {
    row: 'Volume Alerts',
    alerts: [
      {
        title: 'Total Connected Vehicles',
        gauge: {
          name: 'vehicle-connected-count',
          filters: target.combineFilters(filterVehicleWatchdog, filterMMX),
        },
        threshold: 10,
        thresholdType: 'lt',
        message: |||
          Total connected MMX vehicles drops below threshold
        |||,
      },
      {
        title: 'Total Messages Received',
        counter: {
          name: 'adapter-incoming',
          filters: filterMMX,
        },
        threshold: 50,
        message: |||
          Total MMX messages received exceeds threshold
        |||,
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'MMX Release Alerts',
  uid='mmx_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slackWarn],
  },
}))
