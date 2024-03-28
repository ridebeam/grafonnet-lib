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
      description=null,
      min=0,
      max=null,
      thresholdsMode='absolute',
      unit='short',
      tooltipMode='single',
      tooltipSort='none',
      drawStyle='line',
      fillOpacity=7,
      gradientMode='opacity',
      stackingMode='none',
      pointSize=5,
    ):: timeseries.new(
      title=title,
      description=description,
      datasource=datasource,
      min=min,
      max=max,
      thresholdsMode=thresholdsMode,
      unit=unit,
      tooltipMode=tooltipMode,
      tooltipSort=tooltipSort,
      drawStyle=drawStyle,
      fillOpacity=fillOpacity,
      gradientMode=gradientMode,
      stackingMode=stackingMode,
      pointSize=pointSize,
    ),

    fullRow(panel):: panel { span: 12 },
    halfRow(panel):: panel { span: 6 },
    thirdRow(panel):: panel { span: 4 },
    quarterRow(panel):: panel { span: 3 },

    repeatPanel(panel, by, direction):: panel { repeat: by, repeatDirection: direction },

    collapseRow(row):: row { collapse: true, collapsed: true },
  },
}
