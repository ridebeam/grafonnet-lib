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


local targets = {
  serviceUptime: {
    queryLatency: target.timers(
      metric='bq-query-latency',
      groupBys=['query_id'],
    ),
  },
};

local panels = {
  serviceUptime: {
    queryLatencyP50: panel.timeLog2('Query latency P50').addTargets([
      targets.serviceUptime.queryLatency.p50,
    ]),
    queryLatencyP99: panel.timeLog2('Query latency P99').addTargets([
      targets.serviceUptime.queryLatency.p99,
    ]),
  },
};

local rows = {
  serviceUptime: row.new('Queries Latency').addPanels([
    panel.halfRow(p)
    for p in [
      panels.serviceUptime.queryLatencyP50,
      panels.serviceUptime.queryLatencyP99,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'analytics-watchdog',
  uid='analytics-watchdog',
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
    query='analytics-watchdog',
    current='analytics-watchdog',
    hide='variable',
  )
)

.addRows([
  rows.serviceUptime,
])
