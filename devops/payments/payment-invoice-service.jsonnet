local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local panel = helpers.panel;

grafana.dashboard.new(
  'payment-invoice-service',
  uid='payments_payment-invoice-service',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='payment-invoice-service',
    current='payment-invoice-service',
    hide='variable',
  )
)

.addRows(
  [
    k8s.rows.service,
    panel.collapseRow(k8s.rows.postgres),
  ]
)