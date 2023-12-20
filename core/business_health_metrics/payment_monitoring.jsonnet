local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local jwebb = import '../../helper/jwebb.libsonnet';
local vizHelper = import '../../helper/viz.libsonnet';
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local kr_inipay_add_payment_trending = |||
  with src as (
    select 
      *,
      coalesce(parseDateTimeBestEffortOrNull(visitParamExtractString(properties, 'client_event_time')), event_time) as client_event_time,
      visitParamExtractString(properties, 'sceneName') as sceneName,
      visitParamExtractString(properties, 'success') as success
    from 
      jwebb.events
    where $timeFilter
    and event_name in ('sceneLoaded', 'paymentAddBegin', 'paymentAddCompleted')
    and visitParamExtractString(properties, 'countryId')='51'
  ),

  events as (
    select
      user_id,
      event_name,
      success,
      sceneName,
      properties,
      toStartOfDay(event_time) as event_day,
      if (client_event_time <= event_time, client_event_time, event_time) as event_time
    from src
    where $timeFilterByColumn(client_event_time)
  ),

  step1 as (
    select 
      *
    from events
    where event_name = 'sceneLoaded'
    and sceneName='/paymentAndCredit/addPayments'
  ),

  step2 as (
    select 
      *
    from events
    where event_name = 'sceneLoaded'
    and sceneName='/paymentAndCredit/inicis'
  ),

  step3 as (
    select 
      *
    from events
    where event_name = 'paymentAddBegin'
    and visitParamExtractRaw(properties, 'paymentMethod')='"INIPay"'
  ),

  step4 as (
    select 
      *
    from events
    where event_name = 'paymentAddCompleted'
    and visitParamExtractRaw(properties, 'paymentMethod')='"INIPay"'
    and success='true'
  ),

  join_table as (
    select
      s1.user_id as user_id,
      s1.event_time as first_event_time,
      s1.event_day as event_day,
      MIN(s4.event_time) as last_event_time
    from step1 as s1
    inner join step2 as s2
    on s1.user_id = s2.user_id
    inner join step3 as s3
    on s1.user_id = s3.user_id
    inner join step4 as s4
    on s1.user_id = s4.user_id
    where s1.event_time <= s2.event_time and s2.event_time <= s3.event_time and s3.event_time <= s4.event_time
    group by 1,2,3
  ),

  completed as (select
      count(*) as count, event_day
  from join_table
  where date_diff('second', first_event_time, last_event_time) <= 600 group by event_day),

  entry as (select count(*) as count, event_day from step1 group by event_day)

  select event_day, c.count * 100 / e.count as ratio from completed c inner join entry e on c.event_day = e.event_day
|||;




// Add metrics here
local metricGroups = [
  {
    name: 'Korea',
    metrics: [
      {
        title: 'Korea inipay add payment success trending',
        query: kr_inipay_add_payment_trending,
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
    ) 
    for metric in metricGroup.metrics
  ])
  for metricGroup in metricGroups
];

grafana.dashboard.new(
  'Payment Jwebb Monitoring',
  uid='global',
  refresh='1h',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now',
  tags=['generated'],
  editable=true,
  timezone='Asia/Singapore',
)

.addRows(rows)