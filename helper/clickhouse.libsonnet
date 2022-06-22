local panel = import 'timeseries-panel.libsonnet';
local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local clickhouseTarget = grafana.clickhouse;

{
  // dataSource for clickhouse targets on grafana
  dataSourceUIDProd: '_Az-rRXnz',
  dataSourceUIDStg: '',

  init():: {
    target: clickhouseTarget,
    panel: panel.init(), # default to [Altinity plugin for clickhouse] on grafana.core.ridebeam.cloud
  },
}
