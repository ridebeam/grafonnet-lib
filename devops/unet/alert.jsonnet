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
    row: 'Error Rate',
    alerts: [
      {
        title: '[UNET] Add Trip Error Rate',
        custom: {
          name: 'add-trip-success-rate',
          query: '(sum(rate(unet_add_ride_error{namespace="production"})[1m]) OR vector(0)) / sum(rate(unet_add_ride_attempt{namespace="production"})[1m]) * 100',
          alias: 'error add trips',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        message: 'Error ratio of adding trips is over 20%',
        noDataState: 'ok',
      },
      {
        title: '[UNET] Add Location Error Rate',
        custom: {
          name: 'add-location-success-rate',
          query: '(sum(rate(unet_add_location_error{namespace="production"})[1m])  OR vector(0)) / sum(rate(unet_add_location_attempt{namespace="production"})[1m]) * 100',
          alias: 'error add location',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        message: 'Error ratio of adding location is over 20%',
        noDataState: 'ok',
      },
      {
        title: '[UNET] Add Status Error',
        custom: {
          name: 'add-status-error-rate',
          query: '(sum(rate(unet_vehicle_status_update_error{namespace="production"})[1m]) OR vector(0)) / sum(rate(unet_vehicle_status_update_attempt{namespace="production"})[1m]) * 100',
          alias: 'error add status',
          intervalFactor: 2,
        },
        threshold: 20,
        thresholdType: 'gt',
        message: 'Error ratio of adding status of vehicle is over 20%',
        noDataState: 'ok',
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
        noDataState: 'ok',
        message: 'Too many API requests failing with 5xx. Inspect Unet Overview-Unet Service to identify which api has issue',
      },
      {
        title: '[UNET] Beam API Get User Error',
        custom: {
          name: 'beam-api-get-user-error',
          query: 'sum(rate(unet_get_user_info_error{namespace="production"}[1m]))',
          alias: 'rate of get user info api error',
        },
        threshold: 5,
        message: 'Get User Info API failing frequently',
        noDataState: 'ok',
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
