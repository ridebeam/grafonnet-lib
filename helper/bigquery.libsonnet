local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local bqTarget = grafana.bigquery;
local panel = import 'panel.libsonnet';

{
  init():: {
    target: bqTarget,
    panel: panel.init('Google BigQuery'),
  },
}
