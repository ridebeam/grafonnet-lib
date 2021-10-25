local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local prom = grafana.prometheus;

{
  filterKeys(names):: if std.isArray(names)
  then std.map($.filterKey, names)
  else $.filterKey(names),

  filterKey(name):: $.replaceInvalidChars(std.asciiLower(name), '0123456789abcdefghijklmnopqrstuvwxyz', '_'),

  replaceInvalidChars(str, valid, repl)::
    local validChars = std.set(std.stringChars(valid));
    std.join('', std.map(function(c) if std.setMember(c, validChars) then c else repl, std.stringChars(str))),


  equalsFilter(tag, value):: '%s="%s"' % [$.filterKey(tag), value],
  likeFilter(tag, value):: '%s=~"%s"' % [$.filterKey(tag), value],
  combineFilters(a, b):: if std.length(a) > 0 && std.length(b) > 0 then a + ', ' + b else a + b,
  targetFilters(filters, sf=true):: '{%s}' % [$.combineFilters(if sf then $.serviceFilters else '', filters)],

  envFilter: $.equalsFilter('namespace', '$env'),
  serviceFilter: $.equalsFilter('service', '$service'),

  serviceFilters: $.combineFilters(
    $.envFilter,
    $.serviceFilter,
  ),

  groupBys(tags=[]):: if std.length(tags) > 0 then 'by (%s)' % [std.join(', ', $.filterKeys(tags))] else '',

  alias(alias='', groupBys=[])::
    if std.length(groupBys) == 0 then alias
    else if std.length(alias) == 0 then $.aliasFromGroupBys(groupBys)
    else '%s - %s' % [$.aliasFromGroupBys(groupBys), alias],

  aliasFromGroupBys(groupBys=[])::
    if std.length(groupBys) > 0 then '{{%s}}' % [std.join('}} - {{', $.filterKeys(groupBys))] else '',


  timerQuantiles: {
    max: { quantile: '1.00' },
    p99: { quantile: '0.99' },
    p95: { quantile: '0.95' },
    p50: { quantile: '0.50' },
    p05: { quantile: '0.05' },
    min: { quantile: '0.00' },
  },

  gaugeFuncs: {
    min: { func: 'min' },
    avg: { func: 'avg' },
    max: { func: 'max' },
    sum: { func: 'sum' },
  },

  timers(
    metric,
    filters='',
    groupBys=[],
    withServiceFilters=true,
  ):: {
    [name]: $.timer(
      metric=metric,
      timerQuantile=$.timerQuantiles[name],
      alias=name,
      filters=filters,
      groupBys=groupBys,
      withServiceFilters=withServiceFilters,
    )
    for name in std.objectFields($.timerQuantiles)
  },

  timer(
    metric,
    timerQuantile,
    alias='',
    filters='',
    groupBys=[],
    withServiceFilters=true,
  )::
    $.target(
      'histogram_quantile(%s, sum(rate(%s_bucket%s[$__interval])) %s)' % [timerQuantile.quantile, $.filterKey(metric), $.targetFilters(filters, withServiceFilters), $.groupBys(['le'] + groupBys)],
      legendFormat=$.alias(alias, groupBys)
    ),

  gauges(
    metric,
    alignmentPeriod=null,
    filters='',
    groupBys=[],
    unit=null,
    valueType=null,
    withServiceFilters=true,
  ):: {
    [name]: $.gauge(
      metric=metric,
      gaugeFunc=$.gaugeFuncs[name],
      alias=name,
      filters=filters,
      groupBys=groupBys,
      withServiceFilters=withServiceFilters,
    )
    for name in std.objectFields($.gaugeFuncs)
  },

  gauge(
    metric,
    gaugeFunc,
    alias='',
    filters='',
    groupBys=[],
    withServiceFilters=true,
  )::
    $.target(
      '%s(%s%s[$__interval]) %s > 0' % [gaugeFunc.func, $.filterKey(metric), $.targetFilters(filters, withServiceFilters), $.groupBys(groupBys)],
      legendFormat=$.alias(alias, groupBys)
    ),

  counter(
    metric='',
    metrics=[],
    alias='',
    filters='',
    groupBys=[],
    withServiceFilters=true,
  )::
    local metricsList = if std.length(metric) > 0 then [metric] else metrics;
    local metricsAgg = std.join(' + ', std.map(function(m) 'rate(%s%s[$__interval])' % [$.filterKey(m), $.targetFilters(filters, withServiceFilters)], metricsList));

    $.target(
      'sum(%s) %s > 0' % [metricsAgg, $.groupBys(groupBys)],
      legendFormat=$.alias(alias, groupBys)
    ),

  target(expr, legendFormat='')::
    prom.target(expr, legendFormat=legendFormat)
    + {
      withAlias(
        alias,
      ):: self { legendFormat: alias },
    },

}
