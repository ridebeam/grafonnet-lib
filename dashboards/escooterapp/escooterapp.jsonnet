local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

// Show Android and IOS crashes with fatal and non-fatal data
local crashRows = [
  row.new('Crashes').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('Android Crashes', format='').addTargets([
        target.gauge(metric='bq_crash', gaugeFunc=target.gaugeFuncs.sum, includeZero=true, alias='android-fatal', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.equalsFilter('error_type', 'FATAL'))),
        target.gauge(metric='bq_crash', gaugeFunc=target.gaugeFuncs.sum, includeZero=true, alias='android-nonfatal', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.equalsFilter('error_type', 'NON_FATAL')))
      ]),
      panel.counter('IOS Crashes', format='').addTargets([
        target.gauge(metric='bq_crash', gaugeFunc=target.gaugeFuncs.sum, includeZero=true, alias='ios-fatal', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.equalsFilter('error_type', 'FATAL'))),
        target.gauge(metric='bq_crash', gaugeFunc=target.gaugeFuncs.sum, includeZero=true, alias='ios-nonfatal', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.equalsFilter('error_type', 'NON_FATAL')))
      ])
    ]
  ])
];

local startTimeRows = [
  row.new('Start Time').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('Android Start Time', format='ms').addTargets([
        target.gauge(metric='start_time_p50', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='android-p50', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='start_time_p75', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='android-p75', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='start_time_p95', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='android-p95', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='start_time_p99', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='android-p99', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+')))
      ]),
      panel.counter('IOS Start Time', format='ms').addTargets([
        target.gauge(metric='start_time_p50', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='ios-p50', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='start_time_p75', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='ios-p75', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='start_time_p95', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='ios-p95', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='start_time_p99', gaugeFunc=target.gaugeFuncs.max, includeZero=true, alias='ios-p99', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+')))
      ])
    ]
  ])
];

local slowFrameRatioRows = [
  row.new('Slow Frame Ratio').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('Android Slow Frame Ratio', format='%').addTargets([
        target.gauge(metric='screen_sfr_p50', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p50', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_sfr_p75', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p75', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_sfr_p95', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p95', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_sfr_p99', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p99', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+')))
      ]),
      panel.counter('IOS Slow Frame Ratio', format='%').addTargets([
        target.gauge(metric='screen_sfr_p50', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p50', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_sfr_p75', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p75', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_sfr_p95', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p95', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_sfr_p99', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p99', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+')))
      ])
    ]
  ])
];

local frozenFrameRatioRows = [
  row.new('Frozen Frame Ratio').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('Android Frozen Frame Ratio', format='‰').addTargets([
        target.gauge(metric='screen_ffr_p50', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p50', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_ffr_p75', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p75', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_ffr_p95', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p95', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_ffr_p99', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='android-p99', filters=target.combineFilters(target.equalsFilter('platform', 'android'), target.likeFilter('app_version', '1.7+.+')))
      ]),
      panel.counter('IOS Frozen Frame Ratio', format='‰').addTargets([
        target.gauge(metric='screen_ffr_p50', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p50', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_ffr_p75', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p75', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_ffr_p95', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p95', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+'))),
        target.gauge(metric='screen_ffr_p99', gaugeFunc=target.gaugeFuncs.avg, includeZero=true, alias='ios-p99', filters=target.combineFilters(target.equalsFilter('platform', 'ios'), target.likeFilter('app_version', '1.7+.+')))
      ])
    ]
  ])
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Escooterapp Performance',
  uid='escooterapp_escooterapp',
  refresh='1d',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  time_from='now-2d',
  tags=['generated'],
)
.addTemplate(
  template.custom(
    name='env',
    query='production',
    current='production',
    hide='variable',
  )
)
.addTemplate(
  template.custom(
    name='service',
    query='analytics-watchdog',
    current='analytics-watchdog',
    hide='variable',
  )
)
.addRows(
  crashRows + startTimeRows + slowFrameRatioRows + frozenFrameRatioRows
)