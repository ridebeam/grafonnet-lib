local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local paymentsSLAQuery1() =
  |||
    with cte as (
      SELECT
        table_name,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'payments.%'
        AND table_name in [
          'payments.payment_configs',
          'payments.audit_trails',
          'payments.orders',
          'payments.order_retries'
        ]
    )
    select
      SUBSTRING(table_name, 11, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local paymentsSLAQuery2() =
  |||
    with cte as (
      SELECT
        table_name,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'payments.%'
        AND table_name in [
          'payments.user_gateways',
          'payments.primer_payment_method',
          'payments.toss_transactions',
          'payments.primer_transactions'
        ]
    )
    select
      SUBSTRING(table_name, 11, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local paymentsSLAQuery3() =
  |||
    with cte as (
      SELECT
        table_name,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'payments.%'
        AND table_name in [
          'payments.iyzico_transactions',
          'payments.kakao_transactions',
          'payments.inicis_transactions',
          'payments.adyen_transactions'
        ]
    )
    select
      SUBSTRING(table_name, 11, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local questboxSLAQuery() =
  |||
    with cte as (
      SELECT
        table_name,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'questbox.%'
    )
    select
      SUBSTRING(table_name, 11, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local paymentsSLATarget1() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=paymentsSLAQuery1(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local paymentsSLATarget2() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=paymentsSLAQuery2(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local paymentsSLATarget3() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=paymentsSLAQuery3(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local questboxSLATarget() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=questboxSLAQuery(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

grafana.dashboard.new(
  'Payment and Questbox BQ SLA',
  uid='payment_sla',
  refresh='1d',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-90d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  row.new('Payments').addPanels([
    panel.halfRow(
      panel.new(title='Payments 1')
      .addTargets([paymentsSLATarget1()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Payments 2')
      .addTargets([paymentsSLATarget2()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Payments 3')
      .addTargets([paymentsSLATarget3()])
    ) { type: 'barchart' },
  ]),
])

.addRows([
  row.new('Questbox').addPanels([
    panel.halfRow(
      panel.new(title='Questbox')
      .addTargets([questboxSLATarget()])
    ) { type: 'barchart' },
  ]),
])
