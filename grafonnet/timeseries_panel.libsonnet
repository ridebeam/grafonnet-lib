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
   * @param toolTipMode (single, all, hidden)
   * @param datasource (optional) Datasource
   * @param linewidth (default `1`) Line Width, integer from 0 to 10
   * @param decimals (optional) Override automatic decimal precision for legend and tooltip. If null, not added to the json output.
   * @param min_span (optional) Min span
   * @param format (default `short`) Unit of the Y axes
   * @param maxDataPoints (optional) If the data source supports it, sets the maximum number of data points for each series returned.
   * @param thresholds (optional) An array of graph thresholds
   * @param transparent (default `false`) Whether to display the panel without a background.
   * @param interval (defaut: null) A lower limit for the interval.
   *
   * @method addTarget(target) Adds a target object.
   * @method addTargets(targets) Adds an array of targets.
   * @method addSeriesOverride(override)
   * @method addAlert(alert) Adds an alert
   * @method addLink(link) Adds a [panel link](https://grafana.com/docs/grafana/latest/linking/panel-links/)
   * @method addLinks(links) Adds an array of links.
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
    format='short',
    datasource=null,
    height=null,
    nullPointMode='null',
    legendDisplayMode="list",
    legendPlacement="bottom",
    toolTipMode='single',
    thresholds=[],
    links=[],
    transparent=false,
    maxDataPoints=null,
    time_from=null,
    time_shift=null,
    interval=null
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
        mode: toolTipMode,
      },
      legend: {
        displayMode: legendDisplayMode,
        placement: legendPlacement,
        calcs: ['lastNotNull'],
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
          fillOpacity: 7,
          gradientMode: "opacity",
          spanNulls: false,
          showPoints: "auto",
          pointSize: 1,
          stacking: {
            mode: "none",
            group: "A"
          },
          axisPlacement: "auto",
          axisLabel: "",
          scaleDistribution: {
            type: "linear"
          },
          hideFrom: {
            tooltip: false,
            viz: false,
            legend: false
          },
          thresholdsStyle: {
            mode: "off"
          },
          lineStyle: {
            fill: "solid"
          }
        },
        color: {
          mode: "palette-classic"
        },
        mappings: []
      },
      overrides: []
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
  },
}