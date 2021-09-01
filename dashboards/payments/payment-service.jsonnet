local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local panel = import '../../helper/panel.libsonnet';
local gcp = import '../../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;
local k8s = import '../k8s.libsonnet';


local targets = {

  getPaymentConfig: {
    attempt: gcp.counter(
      metric=m('get-payment-config-attempt'),
    ),
    success: gcp.counter(
      metric=m('get-payment-config-success'),
    ),
    failed: gcp.counter(
      metric=m('get-payment-config-failed'),
    ),
    time: gcp.timers(
      metric=m('get-payment-config-timing'),
    ),
  },

  updatePaymentConfig: {
    attempt: gcp.counter(
      metric=m('update-payment-config-attempt'),
    ),
    success: gcp.counter(
      metric=m('update-payment-config-success'),
    ),
    failed: gcp.counter(
      metric=m('update-payment-config-failed'),
    ),
    time: gcp.timers(
      metric=m('update-payment-config-timing'),
    ),
  },

  addRecurring: {
    attempt: gcp.counter(
      metric=m('add-recurring-attempt'),
    ),
    success: gcp.counter(
      metric=m('add-recurring-success'),
    ),
    failed: gcp.counter(
      metric=m('add-recurring-failed'),
    ),
    action: gcp.counter(
      metric=m('add-recurring-action'),
    ),
    cardError: gcp.counter(
      metric=m('add-recurring-error'),
    ),
    time: gcp.timers(
      metric=m('add-recurring-timing'),
    ),
  },

  getRecurring: {
    attempt: gcp.counter(
      metric=m('get-recurring-attempt'),
    ),
    success: gcp.counter(
      metric=m('get-recurring-success'),
    ),
    failed: gcp.counter(
      metric=m('get-recurring-failed'),
    ),
    time: gcp.timers(
      metric=m('get-recurring-timing'),
    ),
  },

  deleteRecurring: {
    attempt: gcp.counter(
      metric=m('delete-recurring-attempt'),
    ),
    success: gcp.counter(
      metric=m('delete-recurring-success'),
    ),
    failed: gcp.counter(
      metric=m('delete-recurring-failed'),
    ),
    time: gcp.timers(
      metric=m('delete-recurring-timing'),
    ),
  },

  createOrder: {
    attempt: gcp.counter(
      metric=m('create-order-attempt'),
    ),
    success: gcp.counter(
      metric=m('create-order-success'),
    ),
    failed: gcp.counter(
      metric=m('create-order-failed'),
    ),
    time: gcp.timers(
      metric=m('create-order-timing'),
    ),
  },

  refundOrder: {
    attempt: gcp.counter(
      metric=m('refund-order-attempt'),
    ),
    success: gcp.counter(
      metric=m('refund-order-success'),
    ),
    failed: gcp.counter(
      metric=m('refund-order-failed'),
    ),
    time: gcp.timers(
      metric=m('refund-order-timing'),
    ),
  },

  cancelOrder: {
    attempt: gcp.counter(
      metric=m('cancel-order-attempt'),
    ),
    success: gcp.counter(
      metric=m('cancel-order-success'),
    ),
    failed: gcp.counter(
      metric=m('cancel-order-failed'),
    ),
    time: gcp.timers(
      metric=m('cancel-order-timing'),
    ),
  },

  retryOrder: {
    attempt: gcp.counter(
      metric=m('retry-order-attempt'),
    ),
    success: gcp.counter(
      metric=m('retry-order-success'),
    ),
    failed: gcp.counter(
      metric=m('retry-order-failed'),
    ),
    time: gcp.timers(
      metric=m('retry-order-timing'),
    ),
  },

  getOrder: {
    attempt: gcp.counter(
      metric=m('get-order-attempt'),
    ),
    success: gcp.counter(
      metric=m('get-order-success'),
    ),
    failed: gcp.counter(
      metric=m('get-order-failed'),
    ),
    time: gcp.timers(
      metric=m('get-order-timing'),
    ),
  },

  handleAdyenNotification: {
    attempt: gcp.counter(
      metric=m('handle-adyen-notification-attempt'),
    ),
    success: gcp.counter(
      metric=m('handle-adyen-notification-success'),
    ),
    failed: gcp.counter(
      metric=m('handle-adyen-notification-failed'),
    ),
    time: gcp.timers(
      metric=m('handle-adyen-notification-timing'),
    ),
  },

  handleAdyen3DS: {
    attempt: gcp.counter(
      metric=m('handle-adyen-3ds-attempt'),
    ),
    success: gcp.counter(
      metric=m('handle-adyen-3ds-success'),
    ),
    failed: gcp.counter(
      metric=m('handle-adyen-3ds-failed'),
    ),
    cardError: gcp.counter(
      metric=m('handle-adyen-3ds-error'),
    ),
    time: gcp.timers(
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
    createOrderTiming: panel.timeLinear('Time Create Order Average').addTargets([
      targets.createOrder.time.avg,
    ]),

    refundOrder: panel.counter('Refund Order').addTargets([
      targets.refundOrder.attempt,
      targets.refundOrder.success,
      targets.refundOrder.failed,
    ]),
    refundOrderTiming: panel.timeLinear('Time Refund Order Average').addTargets([
      targets.refundOrder.time.avg,
    ]),

    cancelOrder: panel.counter('Cancel Order').addTargets([
      targets.cancelOrder.attempt,
      targets.cancelOrder.success,
      targets.cancelOrder.failed,
    ]),
    cancelOrderTiming: panel.timeLinear('Time Cancel Order Average').addTargets([
      targets.cancelOrder.time.avg,
    ]),

    retryOrder: panel.counter('Retry Order').addTargets([
      targets.retryOrder.attempt,
      targets.retryOrder.success,
      targets.retryOrder.failed,
    ]),
    retryOrderTiming: panel.timeLinear('Time Retry Order Average').addTargets([
      targets.retryOrder.time.avg,
    ]),

    getOrder: panel.counter('Get Order').addTargets([
      targets.getOrder.attempt,
      targets.getOrder.success,
      targets.getOrder.failed,
    ]),
    getOrderTiming: panel.timeLinear('Time Get Order Average').addTargets([
      targets.getOrder.time.avg,
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
    addRecurringTiming: panel.timeLinear('Time Add Recurring Average').addTargets([
      targets.addRecurring.time.avg,
    ]),

    getRecurring: panel.counter('Get Recurring').addTargets([
      targets.getRecurring.attempt,
      targets.getRecurring.success,
      targets.getRecurring.failed,
    ]),
    getRecurringTiming: panel.timeLinear('Time Get Recurring Average').addTargets([
      targets.getRecurring.time.avg,
    ]),

    deleteRecurring: panel.counter('Delete Recurring').addTargets([
      targets.deleteRecurring.attempt,
      targets.deleteRecurring.success,
      targets.deleteRecurring.failed,
    ]),
    deleteRecurringTiming: panel.timeLinear('Time Delete Recurring Average').addTargets([
      targets.deleteRecurring.time.avg,
    ]),
  },

  configs: {
    getPaymentConfig: panel.counter('Get Payment Config').addTargets([
      targets.getPaymentConfig.attempt,
      targets.getPaymentConfig.success,
      targets.getPaymentConfig.failed,
    ]),
    getPaymentConfigTiming: panel.timeLinear('Timing Get Payment Config Average').addTargets([
      targets.getPaymentConfig.time.avg,
    ]),

    updatePaymentConfig: panel.counter('Update Payment Config').addTargets([
      targets.updatePaymentConfig.attempt,
      targets.updatePaymentConfig.success,
      targets.updatePaymentConfig.failed,
    ]),
    updatePaymentConfigTiming: panel.timeLinear('Timing Update Payment Config Average').addTargets([
      targets.updatePaymentConfig.time.avg,
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
    ]),

    handleAdyen3DS: panel.counter('Handle Adyen 3DS').addTargets([
      targets.handleAdyen3DS.attempt,
      targets.handleAdyen3DS.success,
      targets.handleAdyen3DS.failed,
      targets.handleAdyen3DS.cardError,
    ]),
    handleAdyen3DSTiming: panel.timeLinear('Timing Handle Adyen 3DS Average').addTargets([
      targets.handleAdyen3DS.time.avg,
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
