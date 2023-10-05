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

local currencyFilter = target.likeFilter('currency', '$currency');

// one entry per row, with a list of panel pairs (counter/timing)
local metrics = [
  {
    row: 'Orders',
    panels: [
      { title: 'Create Order', prefix: 'create-order', counters: ['attempt', 'success', 'failed', 'rejected'] },
      { title: 'Refund Order', prefix: 'refund-order', counters: ['attempt', 'success', 'failed'] },
      { title: 'Cancel Order', prefix: 'cancel-order', counters: ['attempt', 'success', 'failed', 'not-found'] },
      { title: 'Retry Order', prefix: 'retry-order', counters: ['attempt', 'success', 'failed'] },
      { title: 'Get Order', prefix: 'get-order', counters: ['attempt', 'success', 'failed'] },
      { title: 'Hold Order', prefix: 'hold-order', counters: ['attempt', 'success', 'failed', 'not-supported', 'error', 'timeout', 'rejected'] },
    ],
  },
  {
    row: 'Recurring',
    panels: [
      { title: 'Add Recurring', prefix: 'add-recurring', counters: ['attempt', 'success', 'failed', 'action', 'error', 'rejected'] },
      { title: 'Get Recurring', prefix: 'get-recurring', counters: ['attempt', 'success', 'failed'] },
      { title: 'Delete Recurring', prefix: 'delete-recurring', counters: ['attempt', 'success', 'failed'] },
    ],
  },
  {
    row: 'Payment Config',
    panels: [
      { title: 'Get Payment Config', prefix: 'get-payment-config', counters: ['attempt', 'success', 'failed'] },
      { title: 'Update Payment Config', prefix: 'update-payment-config', counters: ['attempt', 'success', 'failed'] },
    ],
  },
  {
    row: 'Adyen',
    panels: [
      { title: 'Handle Adyen Notification', prefix: 'handle-adyen-notification', counters: ['attempt', 'success', 'failed', 'require-resend'] },
      { title: 'Handle Adyen 3DS', prefix: 'handle-adyen-3ds', counters: ['attempt', 'success', 'failed', 'error'] },
    ],
  },
  {
    row: 'Primer',
    panels: [
      { title: 'Handle Primer Notification', prefix: 'handle-primer-notification', counters: ['attempt', 'success', 'failed', 'require-resend'] },
    ],
  },
  {
    row: 'Auth Adjust Timing',
    panels: [
      { title: 'Pre Auth Success Timing', prefix: 'auth-success', counters: [] },
      { title: 'Pre Auth Failed Timing', prefix: 'auth-failed', counters: [] },
    ],
  },
  {
    row: 'AuthAdjust',
    panels: [
      { title: 'AuthAdjust Failed', prefix: 'auth-adjust', counters: ['failure'] },
    ],
  },
    {
    row: 'Capture',
    panels: [
      { title: 'Capture Failed', prefix: 'capture', counters: ['failure'] },
    ],
  }
];

// create a simple counter, with the metric name as alias
local cnt(metric) = target.counter(metric=metric, alias=metric, filters=currencyFilter);
local timers(metric) = target.timers(metric=metric, filters=currencyFilter);

// create for each metric prefix a timer panel and the various counters
local pnls(title, prefix, suffixes) =
  local tmr = timers(metric='%s-timing' % [prefix]);

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
      pnls(panel.title, panel.prefix, panel.counters)
      for panel in r.panels
    ])
  ])
  for r in metrics
];


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
    name='currency',
    query='KRW,AUD,NZD,TRY,MYR,IDR,JPY,THB',
    allValues='.*',
    current='All',
    includeAll=true,
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

.addRows(
  [
    k8s.rows.service,
    panel.collapseRow(k8s.rows.grpc),
    panel.collapseRow(k8s.rows.postgres),
  ]
  + rows,
)
