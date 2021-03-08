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
    $.equalsFilter($.label('env'), '$env'),
    $.equalsFilter($.label('service'), '$service'),
  ),

  podFilters: $.combineFilters(
    $.equalsFilter('resource.label.namespace_name', '$env'),
    $.equalsFilter('metadata.user_labels."app.kubernetes.io/component"', '$service'),
  ),

  podFiltersK8sContainer: $.combineFilters(
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
    filterPods=false,
    filterPodsK8sContainer=false,
    groupBys=[],
    unit=null,
    valueType=null,
  ):: {
    [name]: $.timer(
      alias=name,
      alignmentPeriod=alignmentPeriod,
      reducer=$.timerReducers[name].reducer,
      filters=filters,
      filterPods=filterPods,
      filterPodsK8sContainer=filterPodsK8sContainer,
      groupBys=groupBys,
      metric=metric,
      unit=unit,
      valueType=valueType,
    )
    for name in std.objectFields($.timerReducers)
  },

  timer(
    metric,
    reducer,
    alias=null,
    alignmentPeriod=null,
    filters=[],
    filterPods=false,
    filterPodsK8sContainer=false,
    groupBys=[],
    unit=null,
    valueType=null,
  )::
    local u = if unit != null then unit else 's';
    local vt = if valueType != null then valueType else 'DISTRIBUTION';
    $.target(
      alias=$.alias(groupBys, alias),
      aligner='ALIGN_DELTA',
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      filterPods=filterPods,
      filterPodsK8sContainer=filterPodsK8sContainer,
      groupBys=groupBys,
      metricKind='CUMULATIVE',
      metric=metric,
      reducer=reducer,
      unit=u,
      valueType=vt,
    ),

  gauges(
    metric,
    alignmentPeriod=null,
    filters=[],
    filterPods=false,
    filterPodsK8sContainer=false,
    groupBys=[],
    unit=null,
    valueType=null,
  ):: {
    [name]: $.gauge(
      alias=name,
      aligner=$.gaugeReducers[name].aligner,
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      filterPods=filterPods,
      filterPodsK8sContainer=filterPodsK8sContainer,
      groupBys=groupBys,
      metric=metric,
      reducer=$.gaugeReducers[name].reducer,
      unit=unit,
      valueType=valueType,
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
    filterPods=false,
    filterPodsK8sContainer=false,
    groupBys=[],
    unit=null,
    valueType=null,
  )::
    local vt = if valueType != null then valueType else 'INT64';
    $.target(
      alias=$.alias(groupBys, alias),
      aligner=aligner,
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      filterPods=filterPods,
      filterPodsK8sContainer=filterPodsK8sContainer,
      groupBys=groupBys,
      metricKind='GAUGE',
      metric=metric,
      reducer=reducer,
      unit=unit,
      valueType=vt,
    ),

  counter(
    metric,
    alias=null,
    alignmentPeriod=null,
    filters=[],
    filterPods=false,
    filterPodsK8sContainer=false,
    groupBys=[],
    unit=null,
    valueType=null,
  )::
    local vt = if valueType != null then valueType else 'INT64';
    $.target(
      alias=$.alias(groupBys, alias),
      aligner='ALIGN_RATE',
      alignmentPeriod=alignmentPeriod,
      filters=filters,
      filterPods=filterPods,
      filterPodsK8sContainer=filterPodsK8sContainer,
      groupBys=groupBys,
      metricKind='CUMULATIVE',
      metric=metric,
      reducer='REDUCE_SUM',
      unit=unit,
      valueType=vt,
    ),

  # default target when accessing gcp metrics
  # predefines projectName and adds default filters
  target(
    alias=null,
    aligner,
    alignmentPeriod=null,
    filters=[],
    filterPods=false,
    filterPodsK8sContainer=false,
    groupBys=[],
    metricKind,
    metric,
    reducer,
    unit=null,
    valueType,
  )::
    local a = if alias != null then alias else
      if groupBys != [] then '{{%s}}' % std.join('}} - {{', groupBys);
    local ap = if alignmentPeriod != null then alignmentPeriod else 'stackdriver-auto';
    local f = if filterPods then $.combineFilters($.podFilters, filters) else if filterPodsK8sContainer then $.combineFilters($.podFiltersK8sContainer, filters) else $.combineFilters($.serviceFilters, filters);
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