local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Loyalty GRPC',
  uid='loyalty-grpc',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,stable,staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='loyalty',
    current='loyalty',
    hide='variable',
  )
)

.addTemplate(
  template.new(
    name='grpc_server_method',
    datasource=null,
    query='label_values(grpc_io_server_completed_rpcs{service="loyalty"}, grpc_server_method)',
    current='$__all',
    multi=true,
    includeAll=true,
    refresh=1,
    sort=1,
    hide='variable',
  )
)
.addRows([
  k8s.rows.service,
  panel.fullRow(k8s.rows.grpc),
  panel.fullRow(k8s.rows.grpcPerMethod),
])
