local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local panel = import '../../helper/panel.libsonnet';
local gcp = import '../../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;
local k8s = import '../k8s.libsonnet';


local targets = {
  orders: {
    createSuccess: gcp.counter(
      metric=m('create-order-success'),
    ),
    createFailed: gcp.counter(
      metric=m('create-order-failed'),
    ),
  },
};

local panels = {
  orders: {
    create: panel.counter('Create Order').addTargets([
      targets.orders.createSuccess,
      targets.orders.createFailed,
    ]),
  },
};

local rows = {
  orders: row.new('Orders').addPanels([
    panel.halfRow(p)
    for p in [
      panels.orders.create,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'payment-service',
  uid='payments_payment-service',
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
    query='payment-service',
    current='payment-service',
    hide='variable',
  )
)

.addRows([
  k8s.rows.service,
  panel.collapseRow(k8s.rows.grpc),
  panel.collapseRow(k8s.rows.postgres),
  rows.orders,
])
