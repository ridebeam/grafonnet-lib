local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local cloudwatch = grafana.cloudwatch;
local alertCondition = grafana.alertCondition;
local row = grafana.row;

local prom = import 'promql.libsonnet';
local promHelpers = prom.init();
local promTarget = promHelpers.target;
local promPanel = promHelpers.panel;

local gcp = import 'gcp.libsonnet';

local cloudwatchHelpers = import 'cloudwatch.libsonnet';
local cwHelpers = cloudwatchHelpers.init();
local cwPanel = cwHelpers.panel;

{
  // configure webhook here: https://api.slack.com/apps/A02M0AZ8KEZ
  // https://api.slack.com/apps/A02M0AZ8KEZ/incoming-webhooks?success=1
  // find app on existing channel, and select `Add this app to a channel ...`

  // go to https://grafana.devops.ridebeam.cloud/api/alert-notifications/lookup
  // to get the uid of your notification channel
  slack: { uid: 'tcneVhOnz' },
  slackWarn: { uid: 'z_hJjK57z' },
  slackTest: { uid: '5th60Gc7z' },
  slackData: { uid: 'v22AHAf7k' },
  slackPayments: { uid: '_pd1H0fnk' },
  slackPaymentsCritical: { uid: 'HiHgRzLSz' },
  slackOpsEngineering: { uid: '796wRExVk' },
  slackSettings: { uid: 'DA1AqzY7z' },
  slackCompIntel: { uid: 'YoazTlw7z' },
  slackIotConnectivity: { uid: 'rnbtzKLVk' },
  slackVehicle: { uid: '1XzRz_Y4k' },
  slackTrips: { uid: 'QNvX9FXVk' },
  opsgenie: { uid: 'krSwV2d7k' },
  opsgenieOpsGR: { uid: 'y_LC8a5nk' },
  opsgenieVehicles: { uid: '9NE5WPjnz' },
  opsgenieDataP0: { uid: 'j1kuittIk' },

  coreSlackData: { uid: 'QVVrMvj7z' },
  slackBusinessMonitoring: { uid: 'iFPymc6nz' },
  slackBusinessMonitoringWarning: { uid: 'I6S3segVk' },
  coreSlackPayments: { uid: 'YHpemPvSz' }, // slack channel for alerts-payments for core grafana
  webhooks: { uid: 'qa61c9OVz' },

  notifications: {
    productionAlerts: [$.slack, $.opsgenie],
    productionWarnings: [$.slackWarn],
    test: [$.slackTest],
    opsGRAlerts: [$.slackWarn, $.opsgenieOpsGR],
    vehiclesAlerts: [$.slackVehicle, $.opsgenieVehicles],
    vehiclesWarning: [$.slackVehicle],
    slackAlertsOnly: [$.slack],
    opsEngineeringWarnings: [$.slackOpsEngineering, $.opsgenieOpsGR],
    iotConnectivityAlerts: [$.slackIotConnectivity],
    dataWarnings: [$.slackData],
    dataAlerts: [$.slackData, $.opsgenieDataP0],
  },

  alertDefaults:: {
    format: 'short',
    channels: $.notifications.productionAlerts,
    thresholdType: 'gt',
    evaluateFor: '5m',
    evaluateEvery: '1m',
    reducerType: 'avg',
    queryTimeStart: '5m',
    noDataState: 'no_data',
  },

  counterDefaults:: {
    func: 'rate',
    filters: promTarget.equalsFilter('namespace', 'production'),
  },

  gaugesDefaults:: {
    func: promTarget.gaugeFuncs.max.func,
    groupBys: [],
  },

  timersDefaults:: {
    percentile: 'p99',
  },

  gcpDefaults:: {
    filters: [],
  },
  gcpCountersDefaults:: $.gcpDefaults {
    filters: [],
  },
  gcpGaugesDefaults:: $.gcpDefaults {
    filters: [],
    groupBys: [],
  },
  gcpTimersDefaults:: $.gcpDefaults {
    filters: [],
  },

  defaults:: {
    alerts: $.alertDefaults,
    counters: $.counterDefaults,
    gauges: $.gaugesDefaults,
    timers: $.timersDefaults,

    gcpCounters: $.gcpCountersDefaults,
    gcpGauges: $.gcpGaugesDefaults,
    gcpTimers: $.gcpTimersDefaults,
  },

  newCondition(
    threshold,
    thresholdType,
    operatorType='and',
    queryRefId='A',
    queryTimeEnd='now',
    queryTimeStart='5m',
    reducerParams=[],
    reducerType='avg',
  ):: alertCondition.new(
    evaluatorParams=[threshold],
    evaluatorType=thresholdType,
    operatorType=operatorType,
    queryRefId=queryRefId,
    queryTimeEnd=queryTimeEnd,
    queryTimeStart=queryTimeStart,
    reducerParams=reducerParams,
    reducerType=reducerType,
  ),

  createCounter(metric)::
    promTarget.counter(
      metric=metric.name,
      func=metric.func,
      interval='1m',
      filters=metric.filters,
      includeZero=true,
      withServiceFilters=false,
    ),

  createGauge(metric)::
    promTarget.gauges(
      metric=metric.name,
      interval='1m',
      filters=metric.filters,
      includeZero=true,
      withServiceFilters=false,
      groupBys=metric.groupBys,
    )[metric.func],

  createTimer(metric):: promTarget.timers(
    metric=metric.name,
    interval='1m',
    filters=metric.filters,
    withServiceFilters=false,
  )[metric.percentile],

  createCustom(metric)::
    local factor = if std.objectHas(metric, 'intervalFactor') then metric.intervalFactor else 1;
    promTarget.target(
      expr=metric.query,
      legendFormat=metric.alias,
      intervalFactor=factor,
    ),

  createGCPCounter(metric)::
    metric.gcpHelpers.target.counter(
      metric=metric.name,
      filters=metric.filters,
      withServiceFilters=false,
    ),

  createGCPGauge(metric)::
    local gauges = metric.gcpHelpers.target.gauges(
      metric=metric.name,
      filters=metric.filters,
      groupBys=metric.groupBys,
      withServiceFilters=false,
    );
    if std.length(metric.groupBys) > 0 then
      gauges.sum
    else
      gauges.max
  ,

  createGCPTimer(metric)::
    metric.gcpHelpers.target.timers(
      metric=metric.name,
      filters=metric.filters,
      withServiceFilters=false,
    ).p99,

  // create a simple counter, with the metric name as alias
  createCloudwatchTarget(metric)::
    cloudwatch.target(
      region='default',
      namespace=metric.namespace,
      metric=metric.name,
      dimensions=metric.dimensions,
      period='auto',
    ),

  createTarget(alertDefinition, defaults)::
    if 'counter' in alertDefinition then
      $.createCounter(defaults.counters + alertDefinition.counter)
    else if 'gauge' in alertDefinition then
      $.createGauge(defaults.gauges + alertDefinition.gauge)
    else if 'timer' in alertDefinition then
      $.createTimer(defaults.timers + alertDefinition.timer)
    else if 'custom' in alertDefinition then
      $.createCustom(alertDefinition.custom)
    else if 'cloudwatch' in alertDefinition then
      $.createCloudwatchTarget(alertDefinition.cloudwatch)
    else if 'gcpCounter' in alertDefinition then
      $.createGCPCounter(defaults.gcpCounters + alertDefinition.gcpCounter)
    else if 'gcpGauge' in alertDefinition then
      $.createGCPGauge(defaults.gcpGauges + alertDefinition.gcpGauge)
    else if 'gcpTimer' in alertDefinition then
      $.createGCPTimer(defaults.gcpTimers + alertDefinition.gcpTimer)
    else {},

  panelHelper(alertDefinition, defaults)::
    if 'counter' in alertDefinition then
      promPanel
    else if 'gauge' in alertDefinition then
      promPanel
    else if 'timer' in alertDefinition then
      promPanel
    else if 'custom' in alertDefinition then
      promPanel
    else if 'cloudwatch' in alertDefinition then
      cwPanel
    else if 'gcpCounter' in alertDefinition then
      local def = defaults.gcpCounters + alertDefinition.gcpCounter;
      def.gcpHelpers.panel
    else if 'gcpGauge' in alertDefinition then
      local def = defaults.gcpGauges + alertDefinition.gcpGauge;
      def.gcpHelpers.panel
    else if 'gcpTimer' in alertDefinition then
      local def = defaults.gcpTimers + alertDefinition.gcpTimer;
      def.gcpHelpers.panel
    else {},

  // create for each entry a panel with alert
  createAlert(definition, defaults)::
    local def = defaults.alerts + definition;
    $.panelHelper(def, defaults).new(def.title, format=def.format).addTargets([
      $.createTarget(def, defaults),
    ]).addAlert(
      def.title,
      notifications=def.channels,
      message='%s\n\n%s' % [def.title, def.message],
      forDuration=def.evaluateFor,
      frequency=def.evaluateEvery,
      noDataState=def.noDataState,
    ).addConditions([
      $.newCondition(
        reducerType=def.reducerType,
        threshold=def.threshold,
        thresholdType=def.thresholdType,
        queryTimeStart=def.queryTimeStart,
      ),
    ]),

  // create panels for each row and put two panels side by side
  createRows(alertDefinitions, defaults=$.defaults):: [
    row.new(r.row).addPanels([
      promPanel.halfRow(p)
      for p in [
        if 'showTable' in alert then
          promPanel.showTable($.createAlert(alert, defaults), current=true, sort='current')
        else
          $.createAlert(alert, defaults)
        for alert in r.alerts
      ]
    ])
    for r in alertDefinitions
  ],

}
