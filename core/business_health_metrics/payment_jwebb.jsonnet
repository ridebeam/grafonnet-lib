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

local ratioBasedVolumeQuery(eventName, additionalQueryConditions='') = |||
  with data as (select
    toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) as time_bucket,
    count() as count
  from
    jwebb.events
  where
    $timeFilter
    and event_time < toStartOfHour(now())
    and event_name = '$eventName'
    $additionalQueryConditions
  group by
    time_bucket
  order by
    time_bucket asc),
  
  time_range as (select max(time_bucket + INTERVAL 1 HOUR) as latest, min(time_bucket) as earliest from data),

  early_data as (
  select
    toStartOfHour(toTimezone("event_time", 'Asia/Singapore') + INTERVAL 1 WEEK) as time_bucket,
    count() as last_week_count
  from
    jwebb.events
  where
    event_time >= (select earliest - INTERVAL 1 WEEK from time_range)
    and event_time < (select latest - INTERVAL 1 WEEK from time_range)
    and event_name = '$eventName'
    $additionalQueryConditions
  group by
    time_bucket
  order by
    time_bucket asc
  )

  select (time_bucket +  INTERVAL 1 HOUR) as time_bucket, abs(d.count - e.last_week_count)/e.last_week_count as diff_ratio from data d inner join early_data e on d.time_bucket = e.time_bucket
|||;

local ratioDiff(threshold, queryStart='2h', queryEnd='now') = {
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

local countExceedConditional(threshold, queryStart='2h', queryEnd='now') = {
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

local countLessThanThreshold(threshold, queryStart='2h', queryEnd='now') = {
    type: 'query',
    query: {
      params: [
        'A',
        queryStart,
        queryEnd,
      ],
    },
    reducer: {
      type: 'avg',
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
        title: 'multi add payment failure event (error, 1hour)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, count() from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='submit_multi_payment_success' and visitParamExtractRaw(properties,'success')='"false"'  group by time_bucket order by time_bucket asc
        |||,
        alertName: 'multi add payment failure event is high (app, 1hour)',
        alertCondition: countExceedConditional(10),
        noDataState: 'ok',
        alertMessage: 'please refresh this query to investigate the detailed errors: https://redash.ridebeam.com/queries/26278',
      },

      {
        title: 'multi add payment success event (volume, 1hour)',
        query: ratioBasedVolumeQuery('submit_multi_payment_success'),
        alertName: 'multi add payment success event is quite different from last week (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check the add payment event funnel',
      },

      {
        title: 'multi add payment latency (latency/0.95/s, 1hour)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, quantile(0.95)(visitParamExtractInt(properties, 'spanDurationMs')/1000) as latency from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='submit_multi_payment_success' group by time_bucket order by time_bucket asc
        |||,
        alertName: 'multi add payment latency is high (app, 1hour)',
        alertCondition: countExceedConditional(10),
        noDataState: 'ok', //'no_data'
        alertMessage: 'please check the server log/traces for multi add payment to understand where is the latency from',
      },
    ],
  },

  {
    name: 'primer tokenization',
    metrics: [
      {
        title: 'primer tokenization start (volume, 1hour)',
        query: ratioBasedVolumeQuery('primer_tokenize_success'),
        alertName: 'primer tokenization event is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the primer payment method is enabled and working fine',
      },

      {
        title: 'primer tokenization failed (error, 1h)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, count() from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='primer_tokenize_success' and visitParamExtractRaw(properties,'success')='"false"'  group by time_bucket order by time_bucket asc
        |||,
        alertName: 'primer tokenization failure is high (app, 1h)',
        alertCondition: countExceedConditional(5),
        noDataState: 'ok',
        alertMessage: 'please query the events to check the detailed errors',
      },


      {
        title: 'primer tokenization error (error, 1h)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, count() from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='primer_tokenize_error'  group by time_bucket order by time_bucket asc
        |||,
        alertName: 'primer tokenization error is high (app, 1h)',
        alertCondition: countExceedConditional(5),
        noDataState: 'ok',
        alertMessage: 'please query the events to check the detailed errors',
      },


      {
        title: 'primer tokenization timeout (error, 1h)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, count() from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='primer_tokenize_timeout'  group by time_bucket order by time_bucket asc
        |||,
        alertName: 'primer tokenization timeout is high (app, 5min)',
        alertCondition: countExceedConditional(5),
        noDataState: 'ok',
        alertMessage: 'please query the events to check the detailed errors',
      },
    ],
  },

  {
    name: 'iyzico',
    metrics: [
      {
        title: 'iyzico 3ds loaded (volume, 1hour)',
        query: ratioBasedVolumeQuery('iyzico3DSLoaded'),
        alertName: 'iyzico 3ds loaded event is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the iyzico is enabled and working fine for 3ds',
      },


      {
        title: 'iyzico 3ds completed (volume, 1hour)',
        query: ratioBasedVolumeQuery('iyzico3DSCompleted'),
        alertName: 'iyzico 3ds completed event is low (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the iyzico is enabled and working fine for 3ds',
      }
    ],
  },

  {
    name: 'inipay',
    metrics: [
      {
        title: 'inipay add begin (volume, 1hour)',
        query: ratioBasedVolumeQuery('paymentAddBegin', 'and visitParamExtractRaw(properties, \'paymentMethod\')=\'"INIPay"\''),
        alertName: 'inipay add payment attempt is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check the inipay payment method is working correctly',
      },


      {
        title: 'inipay add completed (volume, 1hour)',
        query: ratioBasedVolumeQuery('paymentAddCompleted', 'and visitParamExtractRaw(properties, \'paymentMethod\')=\'"INIPay"\''),
        alertName: 'inipay add payment complete is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the inipay payment method is working correctly',
      },

      {
        title: 'inipay add failed (error, 1hour)',
        query: ratioBasedVolumeQuery('paymentAddCompleted', 'and visitParamExtractRaw(properties, \'paymentMethod\')=\'"INIPay"\' and visitParamExtractRaw(properties, \'success\')=\'"false"\''),
        alertName: 'inipay add payment failure event is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'ok',
        alertMessage: 'please check if the inipay add payment is working properly',
      }
    ],
  },

  {
    name: 'toss',
    metrics: [
      {
        title: 'toss start generate billing key (volume, 1hour)',
        query: ratioBasedVolumeQuery('toss_billing_key_generation_begin'),
        alertName: 'toss generate billing key event is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the toss payment method is enabled and working fine',
      },

      {
        title: 'toss generate billing key completed (volume, 1hour)',
        query: ratioBasedVolumeQuery('toss_billing_key_generation_completed'),
        alertName: 'toss generate billing key completed is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the toss payment method is enabled and working fine',
      },

      {
        title: 'toss generate billing key error (volume, 1hour)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, count() from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='toss_billing_key_generation_completed' and visitParamExtractRaw(properties, 'success')='"false"'  group by time_bucket order by time_bucket asc
        |||,
        alertName: 'toss generate billing key error is high (app, 1hour)',
        alertCondition: countExceedConditional(3, '2h'),
        noDataState: 'ok',
        alertMessage: 'please check if the toss billing key generation is working correctly',
      },

      {
        title: 'toss redirection completed (volume, 1hour)',
        query: ratioBasedVolumeQuery('toss_redirection_completed'),
        alertName: 'toss redirection completed is low (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the toss redirection is ok',
      },

      {
        title: 'toss redirection error (volume, 1hour)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, count() from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='toss_redirection_completed' and visitParamExtractRaw(properties, 'success')='"false"'  group by time_bucket order by time_bucket asc
        |||,
        alertName: 'toss redirection error is high (app, 1hour)',
        alertCondition: countExceedConditional(3, '2h'),
        noDataState: 'ok',
        alertMessage: 'please check if the toss redirection is working fine',
      },
    ],
  },

  {
    name: 'kakao',
    metrics: [
      {
        title: 'kakao get redirection (volume, 1hour)',
        query: ratioBasedVolumeQuery('kakao_get_redirection_url_begin'),
        alertName: 'kakao get redirection is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the kakao payment method is enabled and working fine',
      },

      {
        title: 'kakao get redirection completed (volume, 1hour)',
        query: ratioBasedVolumeQuery('kakao_get_redirection_url_completed'),
        alertName: 'kakao get redirection completed is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the kakao payment method is enabled and working fine',
      },

      {
        title: 'kakao get redirection error (error, 1hour)',
        query: |||
          select (toStartOfHour(toTimezone("event_time", 'Asia/Singapore')) + INTERVAL 1 HOUR) as time_bucket, count() from jwebb.events where $timeFilter and event_time < toStartOfHour(now()) and event_name='kakao_get_redirection_url_completed' and visitParamExtractRaw(properties, 'success')='"false"'  group by time_bucket order by time_bucket asc
        |||,
        alertName: 'kakao get redirection error is high (app, 1hour)',
        alertCondition: countExceedConditional(3, '2h'),
        noDataState: 'ok',
        alertMessage: 'please check if the kakao get redirection is working fine',
      },

      {
        title: 'kakao webview loaded (volume, 1hour)',
        query: ratioBasedVolumeQuery('kakao_webview_loaded'),
        alertName: 'kakao webview loaded is abnormal (app, 1hour)',
        alertCondition: ratioDiff(0.5),
        noDataState: 'no_data',
        alertMessage: 'please check if the kakao payment method is enabled and working fine',
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
        message=metric.alertMessage,
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