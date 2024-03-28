{
  /**
   * Creates a [time series panel](https://grafana.com/docs/grafana/latest/visualizations/time-series/).
   * It requires the time series panel plugin in grafana, which is built-in.
   *
   * @name timeSeriesPanel.new
   *
   * @param title The title of the time series panel.
   * @param description (optional) The description of the panel
   * @param span (optional) Width of the panel
   * @param legendDisplayMode
   * @param legendPlacement
   * @param tooltipMode (default: `'single'`) 'single', 'multi', 'none'.
   * @param tooltipSort (default: `'none'`) 'asc', 'desc', 'none'.
   * @param datasource (optional) Datasource
   * @param linewidth (default `1`) Line Width, integer from 0 to 10
   * @param decimals (optional) Override automatic decimal precision for legend and tooltip. If null, not added to the json output.
   * @param min_span (optional) Min span
   * @param unit (default `short`) Unit of the Y axes
   * @param maxDataPoints (optional) If the data source supports it, sets the maximum number of data points for each series returned.
   * @param thresholds (optional) An array of graph thresholds
   * @param transparent (default `false`) Whether to display the panel without a background.
   * @param interval (defaut: null) A lower limit for the interval.
   * @param min (optional) Leave empty to calculate based on all values.
   * @param max (optional) Leave empty to calculate based on all values.
   * @param thresholdsMode (default `'absolute'`) 'absolute' or 'percentage'.
   * @param fillOpacity (default `7`) Fill opacity, integer from 0 to 100.
   * @gradientMode (default `'opacity'`) 'opacity', 'hue' or 'none'.
   * @stackingMode (default `'none'`) 'none', 'normal', 'percent'.
   * @pointSize (default `5`) Point size, integer from 1 to 40.
   *
   * @method addTarget(target) Adds a target object.
   * @method addTargets(targets) Adds an array of targets.
   * @method addSeriesOverride(override)
   * @method addAlert(alert) Adds an alert
   * @method addLink(link) Adds a [panel link](https://grafana.com/docs/grafana/latest/linking/panel-links/)
   * @method addLinks(links) Adds an array of links.
   * @method addThreshold(step) Adds a [threshold](https://grafana.com/docs/grafana/latest/panels/thresholds/) step. Argument format: `{ color: 'green', value: 0 }`.
   */
  new(
    title,
    span=null,
    fill=1,
    fillGradient=0,
    linewidth=1,
    drawStyle='line',
    decimals=null,
    description=null,
    min_span=null,
    unit='short',
    datasource=null,
    height=null,
    nullPointMode='null',
    legendDisplayMode='list',
    legendPlacement='bottom',
    tooltipMode='single',
    tooltipSort='none',
    thresholds=[],
    links=[],
    transparent=false,
    maxDataPoints=null,
    time_from=null,
    time_shift=null,
    interval=null,
    spanNulls=false,
    min=null,
    max=null,
    thresholdsMode='absolute',
    fillOpacity=7,
    gradientMode='opacity',
    stackingMode='none',
    pointSize=5,
  ):: {
    title: title,
    [if span != null then 'span']: span,
    [if min_span != null then 'minSpan']: min_span,
    [if decimals != null then 'decimals']: decimals,
    type: 'timeseries',
    datasource: datasource,
    targets: [
    ],
    [if description != null then 'description']: description,
    [if height != null then 'height']: height,
    [if maxDataPoints != null then 'maxDataPoints']: maxDataPoints,
    options: {
      tooltip: {
        mode: tooltipMode,
        [if tooltipMode == 'multi' then 'sort']: tooltipSort,
      },
      legend: {
        displayMode: legendDisplayMode,
        placement: legendPlacement,
        calcs: [],
      },
    },
    nullPointMode: nullPointMode,
    timeFrom: time_from,
    timeShift: time_shift,
    [if interval != null then 'interval']: interval,
    [if transparent == true then 'transparent']: transparent,
    seriesOverrides: [],
    thresholds: thresholds,
    links: links,
    fieldConfig: {
      defaults: {
        custom: {
          drawStyle: drawStyle,
          lineInterpolation: 'smooth',
          barAlignment: 0,
          lineWidth: linewidth,
          fillOpacity: fillOpacity,
          gradientMode: gradientMode,
          spanNulls: spanNulls,
          showPoints: 'never',
          pointSize: pointSize,
          stacking: {
            mode: stackingMode,
            group: 'A',
          },
          axisPlacement: 'auto',
          axisLabel: '',
          scaleDistribution: {
            type: 'linear',
          },
          hideFrom: {
            tooltip: false,
            viz: false,
            legend: false,
          },
          thresholdsStyle: {
            mode: 'off',
          },
          lineStyle: {
            fill: 'solid',
          },
        },
        color: {
          mode: 'palette-classic',
        },
        mappings: [],
        min: min,
        max: max,
        thresholds: {
          mode: thresholdsMode,
          steps: [],
        },
        unit: unit,
      },
      overrides: [],
    },
    _nextTarget:: 0,
    addTarget(target):: self {
      // automatically ref id in added targets.
      // https://github.com/kausalco/public/blob/master/klumps/grafana.libsonnet
      local nextTarget = super._nextTarget,
      _nextTarget: nextTarget + 1,
      targets+: [target { refId: std.char(std.codepoint('A') + nextTarget) }],
    },
    addTargets(targets):: std.foldl(function(p, t) p.addTarget(t), targets, self),
    addSeriesOverride(override):: self {
      seriesOverrides+: [override],
    },
    addAlert(
      name,
      executionErrorState='alerting',
      forDuration='5m',
      frequency='60s',
      handler=1,
      message='',
      noDataState='no_data',
      notifications=[],
      alertRuleTags={},
    ):: self {
      local it = self,
      _conditions:: [],
      alert: {
        name: name,
        conditions: it._conditions,
        executionErrorState: executionErrorState,
        'for': forDuration,
        frequency: frequency,
        handler: handler,
        noDataState: noDataState,
        notifications: notifications,
        message: message,
        alertRuleTags: alertRuleTags,
      },
      addCondition(condition):: self {
        _conditions+: [condition],
      },
      addConditions(conditions):: std.foldl(function(p, c) p.addCondition(c), conditions, it),
    },
    addLink(link):: self {
      links+: [link],
    },
    addLinks(links):: std.foldl(function(p, t) p.addLink(t), links, self),
    addOverride(
      matcher=null,
      properties=null,
    ):: self {
      fieldConfig+: {
        overrides+: [
          {
            [if matcher != null then 'matcher']: matcher,
            [if properties != null then 'properties']: properties,
          },
        ],
      },
    },
    addOverrides(overrides):: std.foldl(function(p, o) p.addOverride(o.matcher, o.properties), overrides, self),
    // thresholds
    addThreshold(step):: self {
      fieldConfig+: { defaults+: { thresholds+: { steps+: [step] } } },
    },
    addThresholds(steps):: std.foldl(function(p, s) p.addThreshold(s), steps, self),
  },
}
