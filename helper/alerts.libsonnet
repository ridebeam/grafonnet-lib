local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local alertCondition = grafana.alertCondition;
local row = grafana.row;

local prom = import 'promql.libsonnet';
local promHelpers = prom.init();
local promTarget = promHelpers.target;
local promPanel = promHelpers.panel;

{
  slack: { uid: 'tcneVhOnz' },
  slackWarn: { uid: 'z_hJjK57z' },
  slackTest: { uid: '5th60Gc7z' },
  opsgenie: { uid: 'krSwV2d7k' },
  opsgenieOpsGR: { uid: 'y_LC8a5nk' },

  notifications: {
    productionAlerts: [$.slack, $.opsgenie],
    productionWarnings: [$.slackWarn],
    test: [$.slackTest],
    opsGRAlerts: [$.slack, $.opsgenieOpsGR],
  },

  alertDefaults:: {
    format: 'short',
    channels: $.notifications.productionAlerts,
    thresholdType: 'gt',
    evaluateFor: '5m',
    reducerType: 'avg',
  },

  counterDefaults:: {
    func: 'rate',
    filters: promTarget.equalsFilter('namespace', 'production'),
  },

  defaults:: {
    alerts: $.alertDefaults,
    counters: $.counterDefaults,
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

  createCounter(metricDef, defaults)::
    local metric = defaults + metricDef;
    promTarget.counter(
      metric=metric.name,
      func=metric.func,
      interval='1m',
      filters=metric.filters,
      includeZero=true,
      withServiceFilters=false,
    ),

  createGauge(metric):: promTarget.gauges(
    metric=metric.name,
    interval='1m',
    filters=metric.filters,
    includeZero=true,
    withServiceFilters=false,
  ).max,

  createTimer(metric):: promTarget.timers(
    metric=metric.name,
    interval='1m',
    filters=metric.filters,
    withServiceFilters=false,
  ).p99,

  createCustom(metric):: promTarget.target(
    expr=metric.query,
    legendFormat=metric.alias,
  ),

  createTarget(alertDefinition, defaults)::
    if 'counter' in alertDefinition then
      $.createCounter(alertDefinition.counter, defaults.counters)
    else if 'gauge' in alertDefinition then
      $.createGauge(alertDefinition.gauge)
    else if 'timer' in alertDefinition then
      $.createTimer(alertDefinition.timer)
    else if 'custom' in alertDefinition then
      $.createCustom(alertDefinition.custom)
    else {},


  // create for each entry a panel with alert
  createAlert(definition, defaults)::
    local def = defaults.alerts + definition;
    [
      promPanel.new(def.title, format=def.format).addTargets([
        $.createTarget(def, defaults),
      ]).addAlert(
        def.title,
        notifications=def.channels,
        message='%s\n\n%s' % [def.title, def.message],
        forDuration=def.evaluateFor,
        frequency='1m',
      ).addConditions([
        $.newCondition(reducerType=def.reducerType, threshold=def.threshold, thresholdType=def.thresholdType),
      ]),
    ],

  // create panels for each row and put two panels side by side
  createRows(alertDefinitions, defaults=$.defaults):: [
    row.new(r.row).addPanels([
      promPanel.halfRow(p)
      for p in std.flattenArrays([
        $.createAlert(alert, defaults)
        for alert in r.alerts
      ])
    ])
    for r in alertDefinitions
  ],

}
