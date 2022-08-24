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
        title: '[UNET] Add Trip',
        custom: {
          name: 'add-trip-success-rate',
          query: 'sum(rate(unet-add-ride-success{namespace="production"})[1m])/sum(rate(unet-add-ride-attempt{namespace="production"})[1m]) * 100',
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
          query: 'sum(rate(unet-add-location-success{namespace="production"})[1m])/sum(rate(unet-add-location-attempt{namespace="production"})[1m]) * 100',
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
