local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local k8s_helper = import '../k8s.libsonnet';
local gcp = import '../../helper/gcp.libsonnet';

local k8s = k8s_helper.init('ridebeam-payments');
local helpers = gcp.init('ridebeam-payments');
local target = helpers.target;
local panel = helpers.panel;
local m = target.customMetric;
local l = target.label;

local targets = {

  getPaymentConfig: {
    attempt: target.counter(
      metric=m('get-payment-config-attempt'),
    ),
    success: target.counter(
      metric=m('get-payment-config-success'),
    ),
    failed: target.counter(
      metric=m('get-payment-config-failed'),
    ),
    time: target.timers(
      metric=m('get-payment-config-timing'),
    ),
  },

  updatePaymentConfig: {
    attempt: target.counter(
      metric=m('update-payment-config-attempt'),
    ),
    success: target.counter(
      metric=m('update-payment-config-success'),
    ),
    failed: target.counter(
      metric=m('update-payment-config-failed'),
    ),
    time: target.timers(
      metric=m('update-payment-config-timing'),
    ),
  },

  addRecurring: {
    attempt: target.counter(
      metric=m('add-recurring-attempt'),
    ),
    success: target.counter(
      metric=m('add-recurring-success'),
    ),
    failed: target.counter(
      metric=m('add-recurring-failed'),
    ),
    action: target.counter(
      metric=m('add-recurring-action'),
    ),
    cardError: target.counter(
      metric=m('add-recurring-error'),
    ),
    time: target.timers(
      metric=m('add-recurring-timing'),
    ),
  },

  getRecurring: {
    attempt: target.counter(
      metric=m('get-recurring-attempt'),
    ),
    success: target.counter(
      metric=m('get-recurring-success'),
    ),
    failed: target.counter(
      metric=m('get-recurring-failed'),
    ),
    time: target.timers(
      metric=m('get-recurring-timing'),
    ),
  },

  deleteRecurring: {
    attempt: target.counter(
      metric=m('delete-recurring-attempt'),
    ),
    success: target.counter(
      metric=m('delete-recurring-success'),
    ),
    failed: target.counter(
      metric=m('delete-recurring-failed'),
    ),
    time: target.timers(
      metric=m('delete-recurring-timing'),
    ),
  },

  createOrder: {
    attempt: target.counter(
      metric=m('create-order-attempt'),
    ),
    success: target.counter(
      metric=m('create-order-success'),
    ),
    failed: target.counter(
      metric=m('create-order-failed'),
    ),
    time: target.timers(
      metric=m('create-order-timing'),
    ),
  },

  refundOrder: {
    attempt: target.counter(
      metric=m('refund-order-attempt'),
    ),
    success: target.counter(
      metric=m('refund-order-success'),
    ),
    failed: target.counter(
      metric=m('refund-order-failed'),
    ),
    time: target.timers(
      metric=m('refund-order-timing'),
    ),
  },

  cancelOrder: {
    attempt: target.counter(
      metric=m('cancel-order-attempt'),
    ),
    success: target.counter(
      metric=m('cancel-order-success'),
    ),
    failed: target.counter(
      metric=m('cancel-order-failed'),
    ),
    time: target.timers(
      metric=m('cancel-order-timing'),
    ),
  },

  retryOrder: {
    attempt: target.counter(
      metric=m('retry-order-attempt'),
    ),
    success: target.counter(
      metric=m('retry-order-success'),
    ),
    failed: target.counter(
      metric=m('retry-order-failed'),
    ),
    time: target.timers(
      metric=m('retry-order-timing'),
    ),
  },

  getOrder: {
    attempt: target.counter(
      metric=m('get-order-attempt'),
    ),
    success: target.counter(
      metric=m('get-order-success'),
    ),
    failed: target.counter(
      metric=m('get-order-failed'),
    ),
    time: target.timers(
      metric=m('get-order-timing'),
    ),
  },

  handleAdyenNotification: {
    attempt: target.counter(
      metric=m('handle-adyen-notification-attempt'),
    ),
    success: target.counter(
      metric=m('handle-adyen-notification-success'),
    ),
    failed: target.counter(
      metric=m('handle-adyen-notification-failed'),
    ),
    time: target.timers(
      metric=m('handle-adyen-notification-timing'),
    ),
  },

  handleAdyen3DS: {
    attempt: target.counter(
      metric=m('handle-adyen-3ds-attempt'),
    ),
    success: target.counter(
      metric=m('handle-adyen-3ds-success'),
    ),
    failed: target.counter(
      metric=m('handle-adyen-3ds-failed'),
    ),
    cardError: target.counter(
      metric=m('handle-adyen-3ds-error'),
    ),
    time: target.timers(
      metric=m('handle-adyen-3ds-timing'),
    ),
  },
};

local panels = {
  orders: {
    createOrder: panel.counter('Create Order').addTargets([
      targets.createOrder.attempt,
      targets.createOrder.success,
      targets.createOrder.failed,
    ]),
    createOrderTiming: panel.timeLinear('Time Create Order').addTargets([
      targets.createOrder.time.avg,
      targets.createOrder.time.p95,
      targets.createOrder.time.p99,
    ]),

    refundOrder: panel.counter('Refund Order').addTargets([
      targets.refundOrder.attempt,
      targets.refundOrder.success,
      targets.refundOrder.failed,
    ]),
    refundOrderTiming: panel.timeLinear('Time Refund Order').addTargets([
      targets.refundOrder.time.avg,
      targets.refundOrder.time.p95,
      targets.refundOrder.time.p99,
    ]),


    cancelOrder: panel.counter('Cancel Order').addTargets([
      targets.cancelOrder.attempt,
      targets.cancelOrder.success,
      targets.cancelOrder.failed,
    ]),
    cancelOrderTiming: panel.timeLinear('Time Cancel Order').addTargets([
      targets.cancelOrder.time.avg,
      targets.cancelOrder.time.p95,
      targets.cancelOrder.time.p99,
    ]),

    retryOrder: panel.counter('Retry Order').addTargets([
      targets.retryOrder.attempt,
      targets.retryOrder.success,
      targets.retryOrder.failed,
    ]),
    retryOrderTiming: panel.timeLinear('Time Retry Order').addTargets([
      targets.retryOrder.time.avg,
      targets.retryOrder.time.p95,
      targets.retryOrder.time.p99,
    ]),

    getOrder: panel.counter('Get Order').addTargets([
      targets.getOrder.attempt,
      targets.getOrder.success,
      targets.getOrder.failed,
    ]),
    getOrderTiming: panel.timeLinear('Time Get Order').addTargets([
      targets.getOrder.time.avg,
      targets.getOrder.time.p95,
      targets.getOrder.time.p99,
    ]),
  },

  recurring: {
    addRecurring: panel.counter('Add Recurring').addTargets([
      targets.addRecurring.attempt,
      targets.addRecurring.success,
      targets.addRecurring.failed,
      targets.addRecurring.action,
      targets.addRecurring.cardError,
    ]),
    addRecurringTiming: panel.timeLinear('Time Add Recurring').addTargets([
      targets.addRecurring.time.avg,
      targets.addRecurring.time.p95,
      targets.addRecurring.time.p99,
    ]),

    getRecurring: panel.counter('Get Recurring').addTargets([
      targets.getRecurring.attempt,
      targets.getRecurring.success,
      targets.getRecurring.failed,
    ]),
    getRecurringTiming: panel.timeLinear('Time Get Recurring').addTargets([
      targets.getRecurring.time.avg,
      targets.getRecurring.time.p95,
      targets.getRecurring.time.p99,
    ]),

    deleteRecurring: panel.counter('Delete Recurring').addTargets([
      targets.deleteRecurring.attempt,
      targets.deleteRecurring.success,
      targets.deleteRecurring.failed,
    ]),
    deleteRecurringTiming: panel.timeLinear('Time Delete Recurring').addTargets([
      targets.deleteRecurring.time.avg,
      targets.deleteRecurring.time.p95,
      targets.deleteRecurring.time.p99,
    ]),
  },

  configs: {
    getPaymentConfig: panel.counter('Get Payment Config').addTargets([
      targets.getPaymentConfig.attempt,
      targets.getPaymentConfig.success,
      targets.getPaymentConfig.failed,
    ]),
    getPaymentConfigTiming: panel.timeLinear('Timing Get Payment Config').addTargets([
      targets.getPaymentConfig.time.avg,
      targets.getPaymentConfig.time.p95,
      targets.getPaymentConfig.time.p99,
    ]),

    updatePaymentConfig: panel.counter('Update Payment Config').addTargets([
      targets.updatePaymentConfig.attempt,
      targets.updatePaymentConfig.success,
      targets.updatePaymentConfig.failed,
    ]),
    updatePaymentConfigTiming: panel.timeLinear('Timing Update Payment Config').addTargets([
      targets.updatePaymentConfig.time.avg,
      targets.updatePaymentConfig.time.p95,
      targets.updatePaymentConfig.time.p99,
    ]),
  },

  adyen: {
    handleAdyenNotification: panel.counter('Handle Adyen Notification').addTargets([
      targets.handleAdyenNotification.attempt,
      targets.handleAdyenNotification.success,
      targets.handleAdyenNotification.failed,
    ]),
    handleAdyenNotificationTiming: panel.timeLinear('Timing Handle Adyen Notification Average').addTargets([
      targets.handleAdyenNotification.time.avg,
      targets.handleAdyenNotification.time.p95,
      targets.handleAdyenNotification.time.p99,
    ]),

    handleAdyen3DS: panel.counter('Handle Adyen 3DS').addTargets([
      targets.handleAdyen3DS.attempt,
      targets.handleAdyen3DS.success,
      targets.handleAdyen3DS.failed,
      targets.handleAdyen3DS.cardError,
    ]),
    handleAdyen3DSTiming: panel.timeLinear('Timing Handle Adyen 3DS Average').addTargets([
      targets.handleAdyen3DS.time.avg,
      targets.handleAdyen3DS.time.p95,
      targets.handleAdyen3DS.time.p99,
    ]),
  },
};

local rows = {
  orders: row.new('Orders').addPanels([
    panel.halfRow(p)
    for p in [
      panels.orders.createOrder,
      panels.orders.createOrderTiming,

      panels.orders.refundOrder,
      panels.orders.refundOrderTiming,

      panels.orders.cancelOrder,
      panels.orders.cancelOrderTiming,

      panels.orders.retryOrder,
      panels.orders.retryOrderTiming,

      panels.orders.getOrder,
      panels.orders.getOrderTiming,
    ]
  ]),

  recurring: row.new('Recurring').addPanels([
    panel.halfRow(p)
    for p in [
      panels.recurring.addRecurring,
      panels.recurring.addRecurringTiming,

      panels.recurring.getRecurring,
      panels.recurring.getRecurringTiming,

      panels.recurring.deleteRecurring,
      panels.recurring.deleteRecurringTiming,
    ]
  ]),

  config: row.new('Payment Config').addPanels([
    panel.halfRow(p)
    for p in [
      panels.configs.getPaymentConfig,
      panels.configs.getPaymentConfigTiming,

      panels.configs.updatePaymentConfig,
      panels.configs.updatePaymentConfigTiming,
    ]
  ]),

  adyen: row.new('Adyen').addPanels([
    panel.halfRow(p)
    for p in [
      panels.adyen.handleAdyenNotification,
      panels.adyen.handleAdyenNotificationTiming,

      panels.adyen.handleAdyen3DS,
      panels.adyen.handleAdyen3DSTiming,
    ]
  ]),
};

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
    name='service',
    query='payment-service',
    current='payment-service',
    hide='variable',
  )
)

.addRows([
  k8s.rows.service,
  panel.collapseRow(k8s.rows.grpc),
  panel.collapseRow(k8s.rows.postgres),
  rows.orders,
  rows.recurring,
  rows.config,
  rows.adyen,
])
