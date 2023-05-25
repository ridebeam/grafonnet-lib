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
  freshness: target.gauge(
    metric='pg-realtime-analytics-freshness',
    groupBys=['table_id'],
    includeZero=true,
    gaugeFunc=target.gaugeFuncs.max,
  ),
};

local panels = {
  freshness: panel.new('Time difference between source table', format='ms').addTargets([
    targets.freshness,
  ]),
};

local rows = {
  freshness: row.new('Data Freshness').addPanels([
    panel.fullRow(p)
    for p in [
      panels.freshness,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Realtime Analytics Freshness',
  uid='realtime-analytics-freshness',
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
    query='analytics-watchdog',
    current='analytics-watchdog',
    hide='variable',
  )
)

.addRows([
  rows.freshness,
])
