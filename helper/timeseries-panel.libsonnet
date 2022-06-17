local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local panel = grafana.timeSeriesPanel;

{
  init(datasource='default'):: {
    datasource: datasource,

    new(
      title,
      description=null,
      format='short',
      time_shift=null,
    ):: panel.new(
      title=title,
      description=description,
      datasource=datasource,
      format=format,
      time_shift=time_shift,
      nullPointMode='null as zero',
    ),

    fullRow(panel):: panel { span: 12 },
    halfRow(panel):: panel { span: 6 },
    thirdRow(panel):: panel { span: 4 },
    quarterRow(panel):: panel { span: 3 },

    collapseRow(row):: row { collapse: true, collapsed: true },
  },
}
