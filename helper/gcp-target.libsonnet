local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local gcmon = grafana.googleCloudMonitoring;

{
  projectName: 'vehicles-283509',
  namespace: 'custom.googleapis.com',
  exporterName: 'opencensus',

  customMetric(name):: '%s/%s/%s' % [$.namespace, $.exporterName, name],
  label(name):: 'metric.label.%s' % [name],

  equalsFilter(metric, value):: [metric, '=', value],
  likeFilter(metric, value):: [metric, '=~', value],
  combineFilters(a, b):: if std.length(a) > 0 && std.length(b) > 0 then a + ['AND'] + b else a + b,

  serviceFilters: $.combineFilters(
    $.equalsFilter('resource.label.namespace_name', '$env'),
    $.equalsFilter('resource.label.container_name', '$service'),
  ),

  timerReducers: {
    p99: { reducer: 'REDUCE_PERCENTILE_99' },
    p95: { reducer: 'REDUCE_PERCENTILE_95' },
    p50: { reducer: 'REDUCE_PERCENTILE_50' },
    p05: { reducer: 'REDUCE_PERCENTILE_05' },
    min: { reducer: 'REDUCE_MIN' },
    avg: { reducer: 'REDUCE_MEAN' },
    max: { reducer: 'REDUCE_MAX' },
  },

  gaugeReducers: {
    p99: { aligner: 'ALIGN_MAX',  reducer: 'REDUCE_PERCENTILE_99' },
    p95: { aligner: 'ALIGN_MAX',  reducer: 'REDUCE_PERCENTILE_95' },
    p50: { aligner: 'ALIGN_MAX',  reducer: 'REDUCE_PERCENTILE_50' },
    p05: { aligner: 'ALIGN_MAX',  reducer: 'REDUCE_PERCENTILE_05' },
    min: { aligner: 'ALIGN_MEAN', reducer: 'REDUCE_MIN' },
    avg: { aligner: 'ALIGN_MEAN', reducer: 'REDUCE_MEAN' },
    max: { aligner: 'ALIGN_MAX',  reducer: 'REDUCE_MAX' },
    sum: { aligner: 'ALIGN_MEAN', reducer: 'REDUCE_SUM' },
  },

  timers(
    metric,
    alignmentPeriod=null,
    filters=[],
    groupBys=[],
    unit=null,
    valueType=null,
    withServiceFilters=true,
  ):: {
    [name]: $.timer(
      alias=name,
      alignmentPeriod=alignmentPeriod,
      reducer=$.timerReducers[name].reducer,
      filters=filters,
      groupBys=groupBys,
      metric=metric,
      unit=unit,
      valueType=valueType,
      withServiceFilters=withServiceFilters,
    )
    for name in std.objectFields($.timerReducers)
  },

  timer(
    metric,
    reducer,
    alias=null,
    alignmentPeriod=null,
    filters=[],
    groupBys=[],
    unit=null,
    valueType=null,
    withServiceFilters=true,
  )::
    local u = if unit != null then unit else 's';
    local vt = if valueType != null then valueType else 'DISTRIBUTION';
    $.target(
      alias=$.alias(groupBys, alias),
      aligner='ALIGN_DELTA',
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      groupBys=groupBys,
      metricKind='CUMULATIVE',
      metric=metric,
      reducer=reducer,
      unit=u,
      valueType=vt,
      withServiceFilters=withServiceFilters,
    ),

  gauges(
    metric,
    alignmentPeriod=null,
    filters=[],
    groupBys=[],
    unit=null,
    valueType=null,
    withServiceFilters=true,
  ):: {
    [name]: $.gauge(
      alias=name,
      aligner=$.gaugeReducers[name].aligner,
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      groupBys=groupBys,
      metric=metric,
      reducer=$.gaugeReducers[name].reducer,
      unit=unit,
      valueType=valueType,
      withServiceFilters=withServiceFilters,
    )
    for name in std.objectFields($.gaugeReducers)
  },

  gauge(
    metric,
    reducer,
    aligner,
    alias=null,
    alignmentPeriod=null,
    filters=[],
    groupBys=[],
    unit=null,
    valueType=null,
    withServiceFilters=true,
  )::
    local vt = if valueType != null then valueType else 'INT64';
    $.target(
      alias=$.alias(groupBys, alias),
      aligner=aligner,
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      groupBys=groupBys,
      metricKind='GAUGE',
      metric=metric,
      reducer=reducer,
      unit=unit,
      valueType=vt,
      withServiceFilters=withServiceFilters,
    ),

  counter(
    metric,
    alias=null,
    aligner='ALIGN_RATE',
    alignmentPeriod=null,
    filters=[],
    groupBys=[],
    unit=null,
    valueType=null,
    withServiceFilters=true,
  )::
    local vt = if valueType != null then valueType else 'INT64';
    $.target(
      alias=$.alias(groupBys, alias),
      aligner=aligner,
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      groupBys=groupBys,
      metricKind='CUMULATIVE',
      metric=metric,
      reducer='REDUCE_SUM',
      unit=unit,
      valueType=vt,
      withServiceFilters=withServiceFilters,
    ),

  # default target when accessing gcp metrics
  # predefines projectName and adds default filters
  target(
    alias=null,
    aligner,
    alignmentPeriod=null,
    filters=[],
    groupBys=[],
    metricKind,
    metric,
    reducer,
    unit=null,
    valueType,
    withServiceFilters=true,
  )::
    local a = if alias != null then alias else
      if groupBys != [] then '{{%s}}' % std.join('}} - {{', groupBys);
    local ap = if alignmentPeriod != null then alignmentPeriod else 'stackdriver-auto';
    local f = if withServiceFilters then $.combineFilters($.serviceFilters, filters) else $.combineFilters($.equalsFilter('resource.label.namespace_name', '$env'),filters);
    local u = if unit != null then unit else '1';
    gcmon.target(
      aliasBy=a,
      alignmentPeriod=ap,
      crossSeriesReducer=reducer,
      filters=f,
      groupBys=groupBys,
      metricKind=metricKind,
      metricType=metric,
      perSeriesAligner=aligner,
      projectName=$.projectName,
      unit=u,
      valueType=valueType,
    ),

  alias(groupBys, alias)::
    if groupBys == null || groupBys == [] then alias
    else if alias == null then $.aliasFromGroupBys(groupBys)
    else '%s - %s' % [$.aliasFromGroupBys(groupBys), alias],

  aliasFromGroupBys(groupBys)::
    if groupBys != [] then '{{%s}}' % std.join('}} - {{', groupBys),

}