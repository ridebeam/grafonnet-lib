local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local panel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local gaugePanel = grafana.gaugePanel;
local timeseries = grafana.timeSeriesPanel;

{
  init(datasource='default'):: {
    datasource: datasource,

    new(
      title,
      description=null,
      format='short',
      legend_show=true,
      percentage=false,
    ):: panel.new(
      title=title,
      description=description,
      datasource=datasource,
      format=format,
      min=0,
      legend_show=legend_show,
      legend_sortDesc=true,
      nullPointMode='null as zero',
      percentage=percentage,
    ),

    counter(
      title,
      description=null,
      format='cps',
      legend_show=true,
      legend_sortDesc=true,
    ):: panel.new(
      title=title,
      description=description,
      datasource=datasource,
      format=format,
      min=0,
      legend_show=legend_show,
      legend_sortDesc=legend_sortDesc,
      nullPointMode='null as zero',
    ),

    timeLinear(
      title,
      description=null,
      format='s',
      legend_show=true,
      lines=true,
      points=false,
      pointradius=5,
      nullPointMode='null as zero',
    ):: panel.new(
      title=title,
      description=description,
      datasource=datasource,
      format=format,
      min=0,
      legend_show=legend_show,
      nullPointMode=nullPointMode,
      lines=lines,
      points=points,
      pointradius=pointradius,
    ),

    timeLog2(
      title,
      description=null,
      format='s',
      legend_show=true,
      min=null,
    )::
      // min of 10ms if undefined
      local m = if min != null then min else if format == 'ms' then '10' else '0.01';
      panel.new(
        title=title,
        description=description,
        datasource=datasource,
        format=format,
        min=min,
        logBase1Y=2,
        logBase2Y=2,
        legend_show=legend_show,
        nullPointMode='null as zero',
      ),

    showTable(
      panel,
      right=true,
      min=false,
      avg=false,
      max=false,
      total=false,
      current=false,
      sort='avg',
    ):: panel {
      legend: {
        show: true,
        alignAsTable: true,
        hideEmpty: true,
        hideZero: true,
        rightSide: right,
        min: min,
        avg: avg,
        max: max,
        total: total,
        current: current,
        values: min || avg || max || total || current,
        sort: sort,
        sortDesc: true,
      },
    },

    stat(
      title,
      description=null,
      unit='none',
      thresholdsMode='absolute',
      min=0,
      max=null,
      reducerFunction='mean',
    ):: statPanel.new(
      title=title,
      description=description,
      datasource=datasource,
      min=min,
      max=max,
      unit=unit,
      thresholdsMode=thresholdsMode,
      reducerFunction=reducerFunction,
    ),

    gauge(
      title,
      description=null,
      unit='none',
      thresholdsMode='absolute',
      min=0,
      max=null,
      reducerFunction='mean',
    ):: gaugePanel.new(
      title=title,
      description=description,
      datasource=datasource,
      min=min,
      max=max,
      unit=unit,
      thresholdsMode=thresholdsMode,
      reducerFunction=reducerFunction,
    ),

    timeseries(
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
      transparent=false,
      maxDataPoints=null,
      time_from=null,
      time_shift=null,
      interval=null
    ):: timeseries.new(
      title=title,
      span=span,
      fill=fill,
      fillGradient=fillGradient,
      linewidth=linewidth,
      drawStyle=drawStyle,
      decimals=decimals,
      description=description,
      min_span=min_span,
      format=format,
      datasource=datasource,
      height=height,
      nullPointMode=nullPointMode,
      legendDisplayMode=legendDisplayMode,
      legendPlacement=legendPlacement,
      toolTipMode=toolTipMode,
      thresholds=thresholds,
      transparent=transparent,
      maxDataPoints=maxDataPoints,
      time_from=time_from,
      time_shift=time_shift,
      interval=interval
    ),

    fullRow(panel):: panel { span: 12 },
    halfRow(panel):: panel { span: 6 },
    thirdRow(panel):: panel { span: 4 },
    quarterRow(panel):: panel { span: 3 },

    repeatPanel(panel, by, direction):: panel { repeat: by, repeatDirection: direction },

    collapseRow(row):: row { collapse: true, collapsed: true },
  },
}
