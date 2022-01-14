local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'analytics-watchdog'),
);

local alertMessage = '%s\nPlease check the followup action: https://docs.google.com/document/d/1YQStb5-RwsH4d5TBg7C8jOE52civRWM6UPDgREWBl4Y/edit?usp=sharing';

local alertDefinitions = [
  {
    row: 'Crashes',
    alerts: [
      {
        title: 'Android Crashes',
        gauge: { name: 'bq_crash', filters: target.combineFilters(target.equalsFilter('platform', 'android'), target.equalsFilter('error_type', 'FATAL')), func: target.gaugeFuncs.sum.func },
        threshold: 200,
        message: alertMessage % "Android fatal crash exceeds 200",
      },

      {
        title: 'IOS Crashes',
        gauge: { name: 'bq_crash', filters: target.combineFilters(target.equalsFilter('platform', 'ios'), target.equalsFilter('error_type', 'FATAL')), func: target.gaugeFuncs.sum.func},
        threshold: 400,
        message: alertMessage % "IOS fatal crash exceeds 200",
      },
    ],
  },


  {
    row: 'Start Time',
    alerts: [
      {
        title: 'Android Start Time',
        gauge: { name: 'start_time_p95', filters: target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+')), func: target.gaugeFuncs.max.func },
        threshold: 5000,
        message: alertMessage % "Android start time p95 exceeds 3s",
      },

      {
        title: 'IOS Start Time',
        gauge: { name: 'start_time_p95', filters: target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+')), func: target.gaugeFuncs.max.func },
        threshold: 5000,
        message: alertMessage % "IOS start time p95 exceeds 3s",
      },
    ],
  },

  {
    row: 'Slow Frame Ratio',
    alerts: [
      {
        title: 'Android Slow Frame Ratio',
        gauge: { name: 'screen_sfr_p75', filters: target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+')), func: target.gaugeFuncs.avg.func},
        threshold: 30,
        message: alertMessage % "Android slow frame ratio P75 exceeds 30%",
      },

      {
        title: 'IOS Slow Frame Ratio',
        gauge: { name: 'screen_sfr_p75', filters: target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+')), func: target.gaugeFuncs.avg.func},
        threshold: 10,
        message: alertMessage % "Android slow frame ratio P75 exceeds 10%",
      },
    ],
  },

  {
    row: 'Frozen Frame Ratio',
    alerts: [
      {
        title: 'Android Frozen Frame Ratio',
        gauge: { name: 'screen_ffr_p95', filters: target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))},
        threshold: 30,
        message: alertMessage % "Android frozen frame ratio P95 exceeds 3%",
      },

      {
        title: 'IOS  Frozen Frame Ratio',
        gauge: { name: 'screen_ffr_p95', filters: target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))},
        threshold: 30,
        message: alertMessage % "IOS frozen frame ratio P95 exceeds 3%",
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts',
  uid='escooterapp_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-2d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: alerts.notifications.productionWarnings,
    evaluateFor: '5m',
  },
}))
