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

local currencyFilter(currency) = target.combineFilters(
  serviceFilter,
  target.likeFilter('currency', currency),
);

local currentNotFilter(currency) = target.combineFilters(
  serviceFilter,
  target.notLikeFilter('currency', currency),
);

local gatewayFilter(gateway) = target.combineFilters(
  serviceFilter,
  target.likeFilter('payment_gateway', gateway),
);

// alert metrics coming from analytics-watchdog
local analyticsWatchdogAlertFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'analytics-watchdog'),
);

local msg = 'Please check the playbook page and look for the corresponding alert code: https://beammobility.atlassian.net/wiki/spaces/BE/pages/2334654469/Payment+Service+Alert+Playbook';

// one entry per row, with a list of panels for each alert (counter/timing)
local failureAlerts = [
  {
    row: 'Order failures',
    alerts: [
      {
        title: '[payment-002] Create Order Failed (KRW)',
        counter: { name: 'create-order-failed', filters: currencyFilter('KRW')},
        threshold: 5,
        message: msg,
      },
      {
        title: '[payment-002] Create Order Failed (AUD|NZD)',
        counter: { name: 'create-order-failed', filters: currencyFilter('AUD|NZD')},
        threshold: 2,
        message: msg,
      },
      {
        title: '[payment-002] Create Order Failed (THB,MYR,TRY,IDR...)',
        counter: { name: 'create-order-failed', filters: currentNotFilter('KRW|AUD|NZD')},
        threshold: 2,
        message: msg,
      },
      {
        title: '[payment-002] Create Order Failed (all currencies)',
        counter: { name: 'create-order-failed' },
        threshold: 10,
        message: msg,
      },
      {
        title: 'Hold Order Failed (KRW)',
        counter: { name: 'hold-order-failed', filters: currencyFilter('KRW') },
        threshold: 5,
        message: msg,
      },
      {
        title: 'Hold Order Failed (AUD|NZD)',
        counter: { name: 'hold-order-failed', filters: currencyFilter('AUD|NZD')  },
        threshold: 3,
        message: msg,
      },
      {
        title: 'Hold Order Failed (THB,MYR,TRY,IDR...)',
        counter: { name: 'hold-order-failed', filters: currentNotFilter('KRW|AUD|NZD') },
        threshold: 3,
        message: msg,
      },
      {
        title: 'Hold Order Failed (all currencies)',
        counter: { name: 'hold-order-failed' },
        threshold: 10,
        message: msg,
      },
      {
        title: 'Hold Order timeout (all currencies)',
        counter: { name: 'hold-order-timeout' },
        threshold: 2,
        message: msg,
      },
      {
        title: '[payment-004] Refund order failed after retrial',
        counter: { name: 'refund-processing-failure' },
        threshold: 1,
        message: msg,
      },
    ],
  },
  {
    row: 'Recurring failures',
    alerts: [
      {
        title: '[payment-001] Add Credit Card Failed (primer)',
        counter: { name: 'add-recurring-failed', filters: gatewayFilter('Primer') },
        threshold: 3,
        message: msg,
      },
      {
        title: '[payment-001] Add Credit Card Failed (adyen)',
        counter: { name: 'add-recurring-failed', filters: gatewayFilter('Adyen') },
        threshold: 3,
        message: msg,
      },
      {
        title: '[payment-001] Add Credit Card Failed (inipay)',
        counter: { name: 'add-recurring-failed', filters: gatewayFilter('Inicis') },
        threshold: 5,
        message: msg,
      },
      {
        title: '[payment-001] Add Credit Card Failed (toss)',
        counter: { name: 'add-recurring-failed', filters: gatewayFilter('Toss') },
        threshold: 2,
        message: msg,
      },
      {
        title: '[payment-001] Add Credit Card Failed (all gateways)',
        counter: { name: 'add-recurring-failed' },
        threshold: 10,
        message: msg,
      },
    ],
  },
  {
    row: 'Notification handling failures',
    alerts: [
      {
        title: '[payment-003] Failed to handle Adyen 3DS',
        counter: { name: 'handle-adyen-3ds-failed' },
        threshold: 10,
        message: msg,
      },
    ],
  },
];

local volumeAlerts = [
  {
    row: 'Order volume',
    alerts: [
      {
        title: '[payment-006] Create order attempt volume low',
        counter: { name: 'create-order-attempt' },
        threshold: 2,
        message: msg,
      },
      {
        title: '[payment-006] Create order success volume low',
        counter: { name: 'create-order-success' },
        threshold: 2,
        message: msg,
      },
    ],
  },
  {
    row: 'Recurring volume',
    alerts: [
      {
        title: '[payment-007] Add Payment attempt volume low',
        counter: { name: 'add-recurring-attempt' },
        threshold: 2,
        message: msg,
      },
      {
        title: '[payment-007] Add Payment success volume low',
        counter: { name: 'add-recurring-success' },
        threshold: 2,
        message: msg,
      },
    ],
  },
];

local abnormalEvents = [
  {
    row: 'Abnormals',
    alerts: [
      {
        title: '[payment-005] Orders stuck in notification',
        counter: { name: 'waiting-on-notification-timeout' },
        threshold: 1,
        message: msg,
      },
      {
        title: '[payment-008] unknown migration version',
        counter: { name: 'unknown-db-migration-version' },
        threshold: 1,
        message: msg,
      },
      {
        title: '[payment-009] handle adyen notification requires re-send',
        counter: { name: 'handle-adyen-notification-require-resend' },
        threshold: 1,
        message: msg,
      },
      {
        title: '[payment-009] handle primer notification requires re-send',
        counter: { name: 'handle-primer-notification-require-resend' },
        threshold: 1,
        message: msg,
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts',
  uid='payments_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(failureAlerts, alerts.defaults {
  alerts+: {
    channels: [alerts.slackPayments],
    evaluateFor: '5m',
    reducerType: 'max',
  },
  counters+: {
    func: 'delta',
    filters: serviceFilter,
  },
}))
.addRows(alerts.createRows(abnormalEvents, alerts.defaults {
  alerts+: {
    channels: [alerts.slackPayments],
    evaluateFor: '5m',
    reducerType: 'sum',
    noDataState: 'ok',
  },
  counters+: {
    func: 'delta',
    filters: serviceFilter,
  },
}))
.addRows(alerts.createRows(volumeAlerts, alerts.defaults {
  alerts+: {
    channels: [alerts.slackPayments],
    evaluateFor: '5m',
    reducerType: 'sum',
    thresholdType: 'lt',
  },
  counters+: {
    func: 'delta',
    filters: serviceFilter,
  },
}))
