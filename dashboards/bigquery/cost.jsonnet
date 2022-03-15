local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local lcdGauge = import '../../helper/lcd-gauge.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local bq_cost = import './raw_bq/bq_cost_panel.json';
local bq_cost_etl = import './raw_bq/bq_cost_etl_panel.json';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  queryCost: target.gauge(
    metric='bq-cost-of-queries',
    includeZero=true,
    groupBys=['query_hash', 'query_type'],
    gaugeFunc=target.gaugeFuncs.sum,
  ) + {
    format: 'table',
    instant: true,
  },
};

local panels = {
  general: {
    queryCost: panel.new('Cost of queries').addTargets([targets.queryCost]) + lcdGauge.new(key='query_hash', value='bytes', unit='decbytes'),
  },
};

local rows = {
  general: row.new('General').addPanels([
    panel.fullRow(p)
    for p in [
      panels.general.queryCost,
      bq_cost,
      bq_cost_etl
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'BQ - Cost',
  uid='bq-data-cost',
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
  rows.general,
])
