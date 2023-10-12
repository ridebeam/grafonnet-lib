local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local template = grafana.template;
local row = grafana.row;
local libProm = grafana.prometheus;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local envFilter = target.equalsFilter('namespace', '$env');

local filterPaymentService = target.combineFilters(
  envFilter,
  target.equalsFilter('service', 'payment-service'),
);
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
    response: target.increase(
      alias='or-response',
      metric='order-retry-job-retry-order-response',
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
    succeeded: target.increase(
      alias='or-succeeded',
      metric='order-retry-job-retry-order-succeeded',
      filters=filterPaymentService,
      withServiceFilters=false,
    ),
    failed: target.increase(
      alias='or-failed',
      metric='order-retry-job-retry-order-failed',
      filters=filterPaymentService,
      withServiceFilters=false,
    ),
    succeededPercent: libProm.target(
      '(sum(increase(order-retry-job-retry-order-succeeded{namespace="$env", service="payment-service"}[2h])))/(sum(increase(order-retry-job-retry-order{namespace="$env", service="payment-service"}[2h]))) > 0',
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
      filters=filterPaymentService,
      withServiceFilters=false,
    ),
  },
  indicators: {
    lastProcessedOrderRetryId: target.gauges(
      alias='last-read-order-retry-id',
      metric='order-retry-id-greatest-processed',
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
    lastUpdatedOrderRetryId: target.gauges(
      alias='last-updated-order-retry-id',
      metric='order-retry-id-greatest-updated',
      filters=filterPaymentAutoService,
      withServiceFilters=false,
    ),
  },
  timing: {
    metricOrderRetryJobFetchLatency: target.histogram(
      alias='order-retry-job-fetch-latency',
      metric='order-retry-job-fetch-latency',
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
    response: panel.new('Order retries response').addTargets([
      targets.orderRetry.response,
    ]),
    failed: panel.new('Order retries failed').addTargets([
      targets.orderRetry.failed,
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
  indicators: {
    lastProcessedOrderRetryId: panel.new('Last read order retry id').addTargets([
      targets.indicators.lastProcessedOrderRetryId,
    ]),
    lastUpdatedOrderRetryId: panel.new('Last updated order retry id').addTargets([
      targets.indicators.lastUpdatedOrderRetryId,
    ]),
  },
  timing: {
    metricOrderRetryJobFetchLatencyP25: panel.timeLog2('Order retry job fetch latency P25').addTargets([
      targets.timing.metricOrderRetryJobFetchLatency.p25,
    ]),
    metricOrderRetryJobFetchLatencyP50: panel.timeLog2('Order retry job fetch latency P50').addTargets([
      targets.timing.metricOrderRetryJobFetchLatency.p50,
    ]),
    metricOrderRetryJobFetchLatencyP99: panel.timeLog2('Order retry job fetch latency P99').addTargets([
      targets.timing.metricOrderRetryJobFetchLatency.p99,
    ]),
  },
};

local rows = {
  orderRetry: row.new('Order Retry Attempted').addPanels([
    panel.halfRow(p)
    for p in [
      panels.orderRetry.attempted,
      panels.orderRetry.response,
    ]
  ]),
  orderRetryResponseFailed: row.new('Order Retry Success and Failed').addPanels([
    panel.halfRow(p)
    for p in [
      panels.orderRetry.succeeded,
      panels.orderRetry.failed,
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
  readAndWriteWatermarks: row.new('Read and Written to watermarks').addPanels([
    panel.halfRow(p)
    for p in [
      panels.indicators.lastProcessedOrderRetryId,
      panels.indicators.lastUpdatedOrderRetryId,
    ]
  ]),
  fetchLatency: row.new('Fetch order retry latencies').addPanels([
    panel.thirdRow(p)
    for p in [
      panels.timing.metricOrderRetryJobFetchLatency25,
      panels.timing.metricOrderRetryJobFetchLatency50,
      panels.timing.metricOrderRetryJobFetchLatency99,
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
  k8s.rows.service,
  rows.orderRetry,
  rows.recovered,
])
