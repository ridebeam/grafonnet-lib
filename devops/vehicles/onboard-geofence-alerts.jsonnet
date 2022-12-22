local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;

// we need to use non-templatized service filters for alerts
local filterVehicleController = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'vehicle-controller'),
);


// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Onboard geofence download',
    alerts: [
      {
        title: 'onboard geofences download via U5',
        custom: {
          name: 'OG-download-succeeded-percent',
          alias: 'percent onboard geofence downloads succeeded',
          query: '100 * (sum(increase(onboard_geofence_upgrade_succeeded{namespace="production", service="iot-server"}[1h])) OR vector(0)) / sum(increase(onboard_geofence_attempt_upgrade{namespace="production", service="iot-server"}[1h]))',
        },
        threshold: 50,
        thresholdType: 'lt',
        evaluateFor: '3h',
        message: 'Onboard geofence download succeeded % is below threshold',
        noDataState: 'ok',
      },
    ],
  },
  {
    row: 'Onboard geofence changes update',
    alerts: [
      {
        title: 'onboard geofences changes handled via GF5',
        custom: {
          name: 'OGCS-Handled-Percent',
          alias: '% of OGCS requests handled',
          query: '100 * (sum(increase(ogcs_target_met{namespace="$env", service="iot-server"}[1h])) OR vector(0)) / sum(increase(onboard_geofence_change_requested{namespace="$env", service="vehicle-controller"}[1h]))',
        },
        threshold: 50,
        thresholdType: 'lt',
        evaluateFor: '3h',
        message: 'Onboard geofence update handled % is below threshold',
        noDataState: 'ok',
      },
      {
        title: 'onboard geofences changes latency',
        timer: {
          name: 'state-changed-latency',
          filters: target.combineFilters(target.equalsFilter('state_name', 'onboardGeofenceChanges'), filterVehicleController),
        },
        format: 's',
        threshold: 180,
        thresholdType: 'gt',
        queryTimeStart: '3m',
        evaluateFor: '30m',
        message: 'Onboard geofence update latency is above 3 minutes (30% of total SLA)',
        noDataState: 'ok',
      },
    ],
  },
];


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Onboard Geofence Alerts',
  uid='onboard_geofence_alerts',
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
