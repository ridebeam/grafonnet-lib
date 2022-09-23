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
local filterOmniATIoT = target.likeFilter('manufacturer', 'omniat');
local filterDeployedVehicle = target.likeFilter('vehicle_status', 'rider|standby');
local globalFilter = target.combineFilterArray([filterIotServer, filterOmniATIoT, filterDeployedVehicle]);


local alertDefaults = {
  format: 'short',
  channels: alerts.notifications.productionAlerts,
  thresholdType: 'gt',
  evaluateFor: '5m',
};

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Error Alerts',
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
          Seeing Omni AT IoT ecuLock error
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
          Seeing  Omni AT battery unlock error
        |||,
      },

      {
        title: 'battery unlock command error',
        counter: {
          name: 'a200-unlock-battery-failure',
          filters: globalFilter,
        },
        threshold: 2,
        noDataState: 'ok',
        message: |||
          battery unlock rto command error
        |||,
      },

      {
        title: 'a200 illegal disassembly alarm',
        counter: {
          name: 'a200-illegal-disassembly-alarm',
          filters: globalFilter,
        },
        threshold: 2,
        noDataState: 'ok',
        message: |||
          a200 illegal disassembly alarm
        |||,
      },

      {
        title: 'a200 unlock command failure',
        counter: {
          name: 'a200-unlock-failure',
          filters: globalFilter,
        },
        threshold: 2,
        noDataState: 'ok',
        message: |||
          a200 unlock command failure
        |||,
      },


      {
        title: 'a200 lock command failure',
        counter: {
          name: 'a200-lock-failure',
          filters: globalFilter,
        },
        threshold: 2,
        noDataState: 'ok',
        message: |||
          a200 lock command failure
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
          Seeing Omni AT helmet lock error
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
          Seeing high volume of Omni AT iot error codes
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
          Seeing Omni AT IoT alarm report exceeds threshold
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
          Seeing Omni AT disconnection count exceeds threshold
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
          Seeing Omni AT IoT helmet lock timing exceeds threshold
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
          filters: target.combineFilters(filterVehicleWatchdog, filterOmniATIoT),
        },
        threshold: 10,
        thresholdType: 'lt',
        message: |||
          Total Omni AT vehicles drops below threshold
        |||,
      },
      {
        title: 'Total Messages Received',
        counter: {
          name: 'adapter-incoming',
          filters: filterOmniATIoT,
        },
        threshold: 50,
        message: |||
          Total Omni AT iot messages received exceeds threshold
        |||,
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Omni AT Alerts',
  uid='omni_at_alerts',
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
