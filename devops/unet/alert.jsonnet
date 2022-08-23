local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local filterService = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'unet'),
);

local alertDefs = [
  {
    row: 'Success Rate',
    alerts: [
      {
        title: '[UNET] Register Vehicles Success Percentage',
        custom: {
          name: 'register-vehicles-success-pct',
          query: 'sum(register_vehicles_success{namespace="production"})/sum(register_vehicles_attempt{namespace="production"}) * 100',
          alias: 'success registered vehicles',
        },
        threshold: 95,
        thresholdType: 'lt',
        message: 'Success ratio of registering vehicles is less than 95%',
      },
      {
        title: '[UNET] Add Trip',
        custom: {
          name: 'add-trip-success-rate',
          query: 'sum(unet-add-ride-success{namespace="production"})/sum(unet-add-ride-attempt{namespace="production"}) * 100',
          alias: 'success added trips',
        },
        threshold: 70,
        thresholdType: 'lt',
        message: 'Success ratio of adding trips is less than 70%',
      },
      {
        title: '[UNET] Add Location',
        custom: {
          name: 'add-location-success-rate',
          query: 'sum(unet-add-location-success{namespace="production"})/sum(unet-add-location-attempt{namespace="production"}) * 100',
          alias: 'success added location',
        },
        threshold: 70,
        thresholdType: 'lt',
        message: 'Success ratio of adding location is less than 70%',
      },
    ],
  },
];

grafana.dashboard.new(
  'Unet Production Alerts',
  uid='unet_alert',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(
  alerts.createRows(alertDefs, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.productionWarnings,
      reducerType: 'avg',
    },
  })
)
