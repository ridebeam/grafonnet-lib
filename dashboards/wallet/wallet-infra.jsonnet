local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

// TODO: custom metrics will be added later
// one entry per row, with a list of panel pairs (counter/timing)
local metrics = [
];

// create a simple counter, with the metric name as alias
local cnt(metric) = target.counter(metric=metric, alias=metric);

// create for each metric prefix a timer panel and the various counters
local pnls(title, prefix, suffixes) =
  local tmr = target.timers('%s-timing' % [prefix]);
  [
    panel.counter(title).addTargets([
      cnt('%s-%s' % [prefix, suffix])
      for suffix in suffixes
    ]),
    panel.timeLinear('Timing %s' % [title]).addTargets([
      tmr.p50,
      tmr.p95,
      tmr.p99,
    ]),
  ];

// create panels for each row and put two panels side by side
local rows = [
  row.new(r.row).addPanels([
    panel.halfRow(p)
    for p in std.flattenArrays([
      pnls(metricPanel.title, metricPanel.prefix, metricPanel.counters)
      for metricPanel in r.panels
    ])
  ])
  for r in metrics
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Wallet Infra',
  uid='wallet_wallet-infra',
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
.addRows(
  [
    k8s.rows.service,
    panel.collapseRow(k8s.rows.grpc),
    panel.collapseRow(k8s.rows.postgres),
  ]
  + rows,
)