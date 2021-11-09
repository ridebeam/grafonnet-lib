local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'payment-service'),
);

local msg = 'Please check the playbook page and look for the corresponding alert code: https://beammobility.atlassian.net/wiki/spaces/BE/pages/2334654469/Payment+Service+Alert+Playbook';

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Orders',
    panels: [
      {
        title: '[payment-002] Create Order Failed',
        counter: 'create-order-failed',
        channels: alerts.notifications.test,
        threshold: 0,
        evaluateFor: '1m',
        message: msg,
      },
    ],
  },
  {
    row: 'Recurring',
    panels: [
      {
        title: '[payment-001] Add Credit Card Failed',
        counter: 'add-recurring-failed',
        channels: alerts.notifications.test,
        threshold: 0,
        evaluateFor: '2m',
        message: msg,
      },
    ],
  },
  {
    row: 'Adyen',
    panels: [
      {
        title: '[payment-003] Failed to handle Adyen 3DS',
        counter: 'handle-adyen-3ds-failed',
        channels: alerts.notifications.test,
        threshold: 0,
        evaluateFor: '2m',
        message: msg,
      },
    ],
  },
];

// create a simple counter, with the metric name as alias
local createCounter(metric) = target.delta(
  metric=metric,
  alias=metric,
  filters=serviceFilter,
  includeZero=true,
  withServiceFilters=false,
);

// create for each entry a counter panel with alert
// TODO support for timer
// TODO move to helper
local createAlert(def) =
  [
    panel.counter(def.title, format='short').addTargets([
      createCounter(def.counter),
    ]).addAlert(
      def.title,
      notifications=def.channels,
      message='%s\n\n%s' % [def.title, def.message],
      forDuration=def.evaluateFor,
      frequency='1m',
    ).addConditions([
      alerts.newCondition(reducerType='max', threshold=def.threshold, thresholdType='gt'),
    ]),
  ];

// create panels for each row and put two panels side by side
local rows = [
  row.new(r.row).addPanels([
    panel.halfRow(p)
    for p in std.flattenArrays([
      createAlert(alert)
      for alert in r.panels
    ])
  ])
  for r in alertDefinitions
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts',
  uid='alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(rows)
