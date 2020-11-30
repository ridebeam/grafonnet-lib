local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local panel = grafana.graphPanel;

local datasource='Stackdriver';

{
  new(
    title,
    format='short',
  ):: panel.new(
      title=title,
      datasource=datasource,
      format=format,
      min=0,
    ),

  counter(
    title,
    format='cps',
  ):: panel.new(
      title=title,
      datasource=datasource,
      format=format,
      min=0,
    ),

  timeLinear(
    title,
    format='s',
  ):: panel.new(
      title=title,
      datasource=datasource,
      format=format,
      min=0,
    ),

  timeLog2(
    title,
    format='s',
  ):: panel.new(      title=title,
      datasource=datasource,
      format=format,
      min='0.01',
      logBase1Y=2,
      logBase2Y=2,
    ),

  halfRow(panel):: panel { span: 6 },
  thirdRow(panel):: panel { span: 4 },
  quarterRow(panel):: panel { span: 3},
}
