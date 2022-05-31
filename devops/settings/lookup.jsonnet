local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local lcdGauge = import '../../helper/lcd-gauge.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  serviceResponseTime: {
    queryLatency: target.timers(
      metric='grpc_io_server_server_latency',
      groupBys=['grpc_server_method'],
    ),
  } + {
    format: 'ms',
    instant: true,
  },
};

local panels = {
  serviceResponseTime: {
    queryLatencyP50: panel.timeLog2('Endpoint latency P50').addTargets([
      targets.serviceResponseTime.queryLatency.p50,
    ]),
    queryLatencyP99: panel.timeLog2('Endpoint latency P99').addTargets([
      targets.serviceResponseTime.queryLatency.p99,
    ]),
  },
};

local rows = {
  serviceResponseTime: row.new('Service Response time').addPanels([
    panel.halfRow(p)
    for p in [
      panels.serviceResponseTime.queryLatencyP50,
      panels.serviceResponseTime.queryLatencyP99,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'settings monitoring',
  uid='settingsLookup',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
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
    query='settings-lookup',
    current='settings-lookup',
    hide='variable',
  )
)

.addRows([
  rows.serviceResponseTime,
])
