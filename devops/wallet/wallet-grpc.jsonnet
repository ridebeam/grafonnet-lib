local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Wallet gRPC',
  uid='wallet_wallet-grpc',
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
    query='wallet',
    current='wallet',
    hide='variable',
  )
)
.addTemplate(
  template.new(
    name='grpc_server_method',
    datasource=null,
    query='label_values(grpc_io_server_completed_rpcs, grpc_server_method)',
    regex='ridebeam.user.Wallet/.+',
    current='$__all',
    multi=true,
    includeAll=true,
    refresh=1,
    sort=1,
    hide='variable',
  )
)
.addRows(
  [
    panel.collapseRow(k8s.rows.grpcPerMethod),
  ]
)