local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

// one entry per row, with a list of panel pairs (counter/timing)
local metrics = [
  {
    row: 'Credit',
    panels: [
      { title: 'Topup Credit Attempt', metric: 'top-up-credit-attempt' },
      { title: 'Topup Credit Success', metric: 'top-up-credit-success' },
      { title: 'Topup Credit Failed', metric: 'top-up-credit-failed' },
      { title: 'Deduct Credit Attempt', metric: 'deduct-credit-attempt' },
      { title: 'Deduct Credit Success', metric: 'deduct-credit-success' },
      { title: 'Deduct Credit Failed', metric: 'deduct-credit-failed' },
      { title: 'Refund Credit Attempt', metric: 'refund-credit-attempt' },
      { title: 'Refund Credit Success', metric: 'refund-credit-success' },
      { title: 'Refund Credit Failed', metric: 'refund-credit-failed' },
    ],
  },
];

// create for each metric prefix a timer panel and the various counters
local pnls(title, metric) =
  [
    panel.counter(title).addTargets([
      target.counter(
        metric=metric,
        groupBys=['currency'],
        filters=target.likeFilter('currency', '$currency')
      )
    ]),
  ];

// create panels for each row and put two panels side by side
local creditRows = [
  row.new(r.row).addPanels([
    panel.thirdRow(p)
    for p in std.flattenArrays([
      pnls(metricPanel.title, metricPanel.metric)
      for metricPanel in r.panels
    ])
  ])
  for r in metrics
];

local jobRows = [
    row.new('Expiring Job').addPanels([
      panel.halfRow(p)
      for p in [
        panel.counter('Expiring Job Success').addTargets([
          target.counter(metric='job-expiring-success')
        ]),
        panel.counter('Expiring Job Failed').addTargets([
          target.counter(metric='job-expiring-failed')
        ])
      ]
    ]),
  ];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Wallet General',
  uid='wallet_wallet-general',
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
    name='currency',
    datasource=null,
    query='label_values(currency)',
    current='$__all',
    multi=true,
    includeAll=true,
    refresh=1,
    sort=1,
  )
)
.addRows(
  creditRows + jobRows
)