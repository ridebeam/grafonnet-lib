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
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"save_primer_failed"\' group by time_bucket',
        alertName: 'primer save payment failure exceed threshold',
        alertCondition: countExceedConditional(0),
      },
      {
        title: 'primer tokenize failure count (error)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_error"\' group by time_bucket',
        alertName: 'primer tokenize failure exceeds threshold',
        alertCondition: countExceedConditional(0),
      },
      {
        title: 'primer tokenize timeout count (error)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_timeout"\' group by time_bucket',
        alertName: 'primer tokenize timeout happens',
        alertCondition: countExceedConditional(0),
      },
      {
        title: 'primer tokenize latency count (latency)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_success"\' and visitParamExtractInt(properties, \'latencyMS\') > 5000 group by time_bucket',
        alertName: 'primer add payment latency is high',
        alertCondition: countExceedConditional(0),
      },
      {
        title: 'primer add payment tokenized success count (volume)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'paymentFSMEvent\' and visitParamExtractRaw(properties,\'step\')=\'"primer_tokenize_success"\' group by time_bucket',
        alertName: 'primer add payment attempts volume is low',
        alertCondition: countLessThanThreshold(10),
      },
    ],
  },

  {
    name: 'primer charge payment metrics',
    metrics: [
      {
        title: 'primer charge order failed (error)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'DO_PAYMENT_FAILED\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' group by time_bucket',
        alertName: 'primer charge order failed',
        alertCondition: countExceedConditional(0),
      },
      {
        title: 'primer charge order success counts (volume)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'DO_PAYMENT_COMPLETED\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' group by time_bucket',
        alertName: 'primer charge order success count',
        alertCondition: countLessThanThreshold(2),
      },
      {
        title: 'primer charge order latency (latency)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'DO_PAYMENT_COMPLETED\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' and visitParamExtractInt(properties, \'latencyMS\') > 5000 group by time_bucket',
        alertName: 'primer charge order success count',
        alertCondition: countExceedConditional(2),
      }
    ],
  },

  {
    name: 'primer refund metrics',
    metrics: [
      {
        title: 'primer refund failed (error)',
        query: 'select toStartOfFiveMinute("event_time") as time_bucket, count() from jwebb.events where $timeFilter and event_name=\'PAYMENT_AUDIT\' and visitParamExtractRaw(properties, \'gateway\')=\'"Primer"\' and visitParamExtractRaw(properties, \'audit_type\')=\'"refund_failed"\' group by time_bucket',
        alertName: 'primer refund failed',
        alertCondition: countExceedConditional(0),
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
  refresh='15m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now+2d',
  tags=['generated'],
  editable=true,
)

.addRows(rows)