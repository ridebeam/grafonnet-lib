local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local template = grafana.template;
local row = grafana.row;
local libProm = grafana.prometheus;
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local envFilter = target.equalsFilter('namespace', '$env');

local filterPaymentAutoService = target.combineFilters(
  envFilter,
  target.equalsFilter('service', 'payment-auto-retry-service'),
);

local targets = {
  orderRetry: {
    attempted: target.increase(
      alias='or-attempted',
      metric='order-retry-job-retry-order',
      groupBys=['retry_count'],
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
    succeeded: target.increase(
      alias='or-succeeded',
      metric='order-retry-job-retry-order-succeeded',
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
    succeededPercent: libProm.target(
      '(sum(increase(order-retry-job-retry-order-succeeded{namespace="$env", service="payment-auto-retry-service"}[2h])))/(sum(increase(order-retry-job-retry-order{namespace="$env", service="payment-auto-retry-service"}[2h]))) > 0',
      legendFormat='%',
      intervalFactor=2,
    ),
    errors: target.increase(
      alias='or-errorred',
      metric='order-retry-job-retry-order-error',
      groupBys=['target_status'],
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
  },
  recovered: {
    amountAttempted: target.increase(
      alias='amount-recovered-attempted',
      metric='order-retry-job-recovered-attempted',
      groupBys=['currency'],
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
    amountRecovered: target.increase(
      alias='amount-recovered',
      metric='order-retry-job-recovered',
      groupBys=['currency'],
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
  },
};

local panels = {
  orderRetry: {
    attempted: panel.counter('Order retries attempted').addTargets([
      targets.orderRetry.attempted,
    ]),
    succeeded: panel.counter(title='Order retries succeeded').addTargets([
      targets.orderRetry.succeeded,
    ]),
    succeededPercent: panel.new('Order retries succeeded %', percentage=true).addTargets([
      targets.orderRetry.succeededPercent,
    ]),
    errorred: panel.new('Order retries errorred', percentage=true).addTargets([
      targets.orderRetry.errors,
    ]),
  },
  recovered: {
    recoveredAttempted: panel.counter('Amount recovered attempted').addTargets([
      targets.recovered.amountAttempted,
    ]),
    recoveredSucceeded: panel.counter(title='Amount recovered').addTargets([
      targets.recovered.amountRecovered,
    ]),
  },
};

local rows = {
  orderRetry: row.new('Order Retry Attempted').addPanels([
    panel.halfRow(p)
    for p in [
      panels.orderRetry.attempted,
      panels.orderRetry.succeeded,
    ]
  ]),
  orderRetrySuccessError: row.new('Order Retry Success %/Errors').addPanels([
    panel.halfRow(p)
    for p in [
      panels.orderRetry.succeededPercent,
      panels.orderRetry.errorred,
    ]
  ]),
  recovered: row.new('Recovered amount').addPanels([
    panel.halfRow(p)
    for p in [
      panels.recovered.recoveredAttempted,
      panels.recovered.recoveredSucceeded,
    ]
  ]),

};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'payment-auto-retry-service',
  uid='payments_payment-auto-retry-service',
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
    query='payment-auto-retry-service',
    current='payment-auto-retry-service',
    hide='variable',
  )
)

.addRows([
  rows.orderRetry,
  rows.recovered,
])
