local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local jwebb = import '../../helper/jwebb.libsonnet';
local vizHelper = import '../../helper/viz.libsonnet';
local clickhouse = import '../../helper/clickhouse.libsonnet';
local alertsHelper = import '../../helper/alerts.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local countExceedConditional(threshold, queryStart='20m', queryEnd='now') = {
    type: 'query',
    query: {
      params: [
        'A',
        queryStart,
        queryEnd,
      ],
    },
    reducer: {
      type: 'max',
      params: [],
    },
    evaluator: {
      type: 'gt',
      params: [
        threshold,
      ],
    },
  };

local countLessThanThreshold(threshold, queryStart='20m', queryEnd='now') = {
    type: 'query',
    query: {
      params: [
        'A',
        queryStart,
        queryEnd,
      ],
    },
    reducer: {
      type: 'max',
      params: [],
    },
    evaluator: {
      type: 'lt',
      params: [
        threshold,
      ],
    },
  };

// Add metrics here
local metricGroups = [
  {
    name: 'multi add payment metrics (primer, iyzico, adyen, xendit)',
    metrics: [
      {
        title: 'multi add payment failure event (error, 5min)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'submit_multi_payment_success\' and visitParamExtractRaw(properties,\'success\')=\'"false"\'  group by time_bucket order by time_bucket asc',
        alertName: 'multi add payment failure event is high (app, 5min)',
        alertCondition: countExceedConditional(5),
        noDataState: 'ok',
      },

      {
        title: 'multi add payment failure event (error, 1hour)',
        query: 'select toStartOfHour(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'submit_multi_payment_success\' and visitParamExtractRaw(properties,\'success\')=\'"false"\'  group by time_bucket order by time_bucket asc',
        alertName: 'multi add payment failure event is high (app, 1hour)',
        alertCondition: countExceedConditional(30, '2h', 'now-1h'),
        noDataState: 'ok',
      },


      {
        title: 'multi add payment success event (volume, 1hour)',
        query: 'select toStartOfHour(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'submit_multi_payment_success\' and visitParamExtractRaw(properties,\'success\')=\'"true"\'  group by time_bucket order by time_bucket asc',
        alertName: 'multi add payment success event falls low (app, 1hour)',
        alertCondition: countLessThanThreshold(20, '2h', 'now-1h'),
        noDataState: 'ok',
      },

      {
        title: 'multi add payment latency (latency/0.95/s, 5min)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, quantile(0.95)(visitParamExtractInt(properties, \'spanDurationMs\')/1000) as latency from jwebb.events where $timeFilter and event_name=\'submit_multi_payment_success\' group by time_bucket order by time_bucket asc',
        alertName: 'multi add payment latency is high (app, 5min)',
        alertCondition: countExceedConditional(10),
        noDataState: 'ok', //'no_data'
      },


      {
        title: 'multi add payment latency (latency/0.95/s, 1hour)',
        query: 'select toStartOfHour(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, quantile(0.95)(visitParamExtractInt(properties, \'spanDurationMs\')/1000) as latency from jwebb.events where $timeFilter and event_name=\'submit_multi_payment_success\' group by time_bucket order by time_bucket asc',
        alertName: 'multi add payment latency is high (app, 1hour)',
        alertCondition: countExceedConditional(10, '2h', 'now-1h'),
        noDataState: 'ok', //'no_data'
      },
    ],
  },
];

local jwebbTarget(datasourceUID, query) = 
  target.target(
    datasourceUID=datasourceUID,
    query=query,
    dateTimeColDataType='event_time',
    database='jwebb',
    table='events',
  )
;

local rows = [
  row.new(metricGroup.name).addPanels([
    panel.halfRow(
      panel.new(title=metric.title)
      .addTargets([
        jwebbTarget(clickhouse.dataSourceUIDProd, metric.query)
      ])
      .addAlert(
        name=metric.alertName,
        noDataState=metric.noDataState,
        notifications=[alertsHelper.coreSlackPayments],
      )
      .addConditions([
        metric.alertCondition
      ])
    ) 
    for metric in metricGroup.metrics
  ])
  for metricGroup in metricGroups
];

grafana.dashboard.new(
  'Payment App Side Monitoring',
  uid='global',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-3h',
  time_to='now',
  tags=['generated'],
  editable=true,
  timezone='Asia/Singapore',
)

.addRows(rows)