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

local countExceedConditional(threshold) = {
    type: 'query',
    query: {
      params: [
        'A',
        '20m',
        'now',
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

local countLessThanThreshold(threshold) = {
    type: 'query',
    query: {
      params: [
        'A',
        '20m',
        'now',
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
    name: 'primer add payment metrics',
    metrics: [
      {
        title: 'primer save payment failure count (error)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"save_primer_failed"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer save payment failure exceed threshold',
        alertCondition: countExceedConditional(0),
        noDataState: 'ok',
      },
      {
        title: 'primer tokenize failure count (error)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_error"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer tokenize failure exceeds threshold',
        alertCondition: countExceedConditional(0),
        noDataState: 'ok',
      },
      {
        title: 'primer tokenize timeout count (error)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_timeout"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer tokenize timeout happens',
        alertCondition: countExceedConditional(0),
        noDataState: 'ok',
      },
      {
        title: 'primer tokenize latency (latency/0.95/s)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, quantile(0.95)(visitParamExtractInt(properties, \'latencyMS\')/1000) as latency from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_success"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer add payment latency is high',
        alertCondition: countExceedConditional(5),
        noDataState: 'ok', //'no_data'
      },
      {
        title: 'primer add payment tokenized success count (volume)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_success"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer add payment attempts volume is low',
        alertCondition: countLessThanThreshold(1),
        noDataState: 'ok', //'no_data'
      },
    ],
  },

  {
    name: 'primer charge payment metrics',
    metrics: [
      {
        title: 'primer charge order failed (error)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'DO_PAYMENT_FAILED\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' and visitParamExtractRaw(properties, \'error\') not in (\'"failed to charge"\') group by time_bucket order by time_bucket asc',
        alertName: 'primer charge order failed',
        alertCondition: countExceedConditional(0),
        noDataState: 'ok',
      },
      {
        title: 'primer charge order success counts (volume)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'DO_PAYMENT_COMPLETED\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer charge order success count',
        alertCondition: countLessThanThreshold(2),
        noDataState: 'no_data',
      },
      {
        title: 'primer charge order latency (latency/0.95/s)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, quantile(0.95)(visitParamExtractInt(properties, \'latencyMS\')/1000) as latency from jwebb.events where $timeFilter and event_name=\'DO_PAYMENT_COMPLETED\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer charge order latency is high',
        alertCondition: countExceedConditional(8),
        noDataState: 'no_data',
      }
    ],
  },

  {
    name: 'primer refund metrics',
    metrics: [
      {
        title: 'primer refund failed (error)',
        query: 'select toStartOfFiveMinute(toTimezone("event_time", \'Asia/Singapore\')) as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'PAYMENT_AUDIT\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' and visitParamExtractRaw(properties, \'audit_type\')=\'"refund_failed"\' group by time_bucket order by time_bucket asc',
        alertName: 'primer refund failed',
        alertCondition: countExceedConditional(0),
        noDataState: 'ok',
      }
    ],
  }
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
        notifications=[alertsHelper.slackBusinessMonitoringWarning],
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
  'Primer Payment Metrics',
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