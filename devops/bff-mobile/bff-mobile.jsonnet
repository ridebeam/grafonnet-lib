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

// one entry per row, with a list of panel pairs (counter/timing)
local metrics = [
  {
    row: 'GraphQL',
    panels: [
      { title: 'GraphQL Request', prefix: 'gql-request', counters: ['handled', 'error'], groupBys: ['gql_operation_name'] },
      // { title: 'GraphQL Request Timing', prefix: 'gql-request-timing', counters: [], groupBys: ['gql_operation_name'] },
    ],
  },
  {
    row: 'Beam-API',
    panels: [
      { title: 'Beam-API Request', prefix: 'beam-api-request', counters: ['handled', 'error'], groupBys: ['beam_api_request_url'] },
      // { title: 'Beam-API Request Timing', prefix: 'beam-api-request-timing', counters: [], groupBys: ['beam_api_request_url'] },
    ],
  },

];

// create a simple counter, with the metric name as alias
local cnt(metric, groupBys) = target.counter(metric=metric, alias=metric, groupBys=groupBys);

// create for each metric prefix a timer panel and the various counters
local pnls(title, prefix, suffixes, groupBys) =
  local tmr = target.timers('%s-timing' % [prefix], groupBys=groupBys);

  [
    panel.counter(title).addTargets([
      cnt('%s-%s' % [prefix, suffix], groupBys)
      for suffix in suffixes
    ]),

    panel.timeLinear('Timing %s' % [title]).addTargets([
      tmr.p95,
    ]),

  ];

// create panels for each row and put two panels side by side
local rows = [
  row.new(r.row).addPanels([
    panel.halfRow(p)
    for p in std.flattenArrays([
      pnls(panel.title, panel.prefix, panel.counters, panel.groupBys)
      for panel in r.panels
    ])
  ])
  for r in metrics
];


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'bff-mobile',
  uid='bff-mobile',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='stable,staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='bff-mobile',
    current='bff-mobile',
    hide='variable',
  )
)

.addRows(
  [
    k8s.rows.service,
    panel.collapseRow(k8s.rows.grpc),
  ]
  + rows,
)
