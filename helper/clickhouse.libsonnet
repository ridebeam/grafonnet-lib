local panel = import 'timeseries-panel.libsonnet';
local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local clickhouseTarget = grafana.clickhouse;

{
  init():: {
    target: clickhouseTarget,
    panel: panel.init(), # default to [Altinity plugin for clickhouse] on grafana.core.ridebeam.cloud
  },
}
