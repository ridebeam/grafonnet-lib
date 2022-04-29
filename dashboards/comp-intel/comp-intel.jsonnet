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
  vehicle_count: {
    query: target.delta(
      metric='compintel_scrape_vehicles_sum',
      groupBys=['competitor'],
    ),
  } + {
    format: 'unit',
    instant: true,
  },
  comp_success_job: {
    query: target.delta(
      metric='compintel_scrape_success',
      groupBys=['competitor'],
    ),
  } + {
    format: 'unit',
    instant: true,
  },
  comp_timer: {
    query: target.delta(
      metric='compintel_scrape_duration_sum',
      groupBys=['competitor'],
    ),
  } + {
    format: 'unit',
    instant: true,
  },
};

local panels = {
  vehicle_count: {
    query: panel.counter('Vehicle Count', format='vehicles').addTargets([
      targets.vehicle_count.query,
    ]),
  },
  comp_success_job: {
    query: panel.counter('Success Job', format='report').addTargets([
      targets.comp_success_job.query,
    ]),
  },
  comp_timer: {
    query: panel.counter('Timer', format='seconds').addTargets([
      targets.comp_timer.query,
    ]),
  },
};

local rows = {
  vehicle_count: row.new('Vehicle Count').addPanels([
    panel.halfRow(p)
    for p in [
      panels.vehicle_count.query,
    ]
  ]),
  comp_timer: row.new('Comp Timer').addPanels([
    panel.halfRow(p)
    for p in [
      panels.comp_success_job.query,
      panels.comp_timer.query,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'comp-intel monitoring',
  uid='comp_intel',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='comp-intel',
    current='comp-intel',
    hide='variable',
  )
)

.addRows([
  rows.vehicle_count,
  rows.comp_timer,
])
