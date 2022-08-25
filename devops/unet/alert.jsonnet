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
          query: 'sum(rate(unet_add_ride_success{namespace="production"})[1m])/sum(rate(unet_add_ride_attempt{namespace="production"})[1m]) * 100',
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
          query: 'sum(rate(unet_add_location_success{namespace="production"})[1m])/sum(rate(unet_add_location_attempt{namespace="production"})[1m]) * 100',
          alias: 'success added location',
        },
        threshold: 70,
        thresholdType: 'lt',
        message: 'Success ratio of adding location is less than 70%',
      },
    ],
  },
  {
    row: 'Kafka Consumption Lag',
    alerts: [
      {
        title: '[UNET] kafka consumption lag: vehicle-event',
        timer: {
          name: 'kafka-consume-lag',
          filters: target.combineFilters(
            filterService,
            target.equalsFilter('kafka_source_topic', 'vehicle-event'),
          ),
        },
        format: 's',
        threshold: 10,
        message: 'unet kafka consuming vehicle events lag > 10s',
      },
      {
        title: '[UNET] kafka consumption lag: trip-events',
        timer: {
          name: 'kafka-consume-lag',
          filters: target.combineFilters(
            filterService,
            target.equalsFilter('kafka_source_topic', 'trip-events'),
          ),
        },
        format: 's',
        threshold: 10,
        message: 'unet kafka consuming trip events lag > 10s',
      },
    ],
  },
  {
    row: 'API Request failure',
    alerts: [
      {
        title: '[UNET] UNET API Pct of 5xx errors',
        custom: {
          name: 'unet-api-pct-rate-of-5xx-errors-ratio',
          query: '((sum(rate(unet_api_request{namespace="production", unet_api_response_status=~"5.."}[1m])) OR vector(0)) / sum(rate(unet_api_request{namespace="production"}[1m]))) * 100',
          alias: 'percentage rate of 5xx errors to rate of total requests',
        },
        threshold: 1,
        message: 'Too many API requests failing with 5xx. Inspect Unet Overview-Unet Service to identify which api has issue',
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
