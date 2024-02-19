local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local liveescooterSLAQuery() =
  |||
    with cte as (  
        SELECT 
            freshness_in_minutes,
            if(freshness_in_minutes <= 60*24,1,0) as ok
        FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
    )
    select
        100*sum(ok)/count(*) as pct
    from cte
  |||
;

local experimentSLAQuery() =
  |||
    with cte as (  
        SELECT 
            freshness_in_minutes,
            if(freshness_in_minutes <= 60*24,1,0) as ok
        FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'experiment.%'
    )
    select
        100*sum(ok)/count(*) as pct
    from cte
  |||
;

local franchiseSLAQuery() =
  |||
    with cte as (  
        SELECT 
            freshness_in_minutes,
            if(freshness_in_minutes <= 60*24,1,0) as ok
        FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'franchise.%'
    )
    select
        100*sum(ok)/count(*) as pct
    from cte
  |||
;

local opsSLAQuery() =
  |||
    with cte as (  
        SELECT 
            freshness_in_minutes,
            if(freshness_in_minutes <= 60*24,1,0) as ok
        FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'ops.%'
    )
    select
        100*sum(ok)/count(*) as pct
    from cte
  |||
;

local paymentsSLAQuery() =
  |||
    with cte as (  
        SELECT 
            freshness_in_minutes,
            if(freshness_in_minutes <= 60*24,1,0) as ok
        FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'payments.%'
    )
    select
        100*sum(ok)/count(*) as pct
    from cte
  |||
;

local questboxSLAQuery() =
  |||
    with cte as (  
        SELECT 
            freshness_in_minutes,
            if(freshness_in_minutes <= 60*24,1,0) as ok
        FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'questbox.%'
    )
    select
        100*sum(ok)/count(*) as pct
    from cte
  |||
;

local liveescooterSLATarget() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local experimentSLATarget() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=experimentSLAQuery(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local franchiseSLATarget() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=franchiseSLAQuery(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local opsSLATarget() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=opsSLAQuery(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local paymentsSLATarget() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=paymentsSLAQuery(),
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
  'SLA by Namespace',
  uid='bq_sla',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-90d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  row.new('Liveescooter Experiment').addPanels([
    panel.halfRow(
      panel.new(title='Liveescooter')
      .addTargets([liveescooterSLATarget()])
    ) { type: 'gauge' },
    panel.halfRow(
      panel.new(title='Experiment')
      .addTargets([experimentSLATarget()])
    ) { type: 'gauge' },
  ]),
])

.addRows([
  row.new('Franchise OPS').addPanels([
    panel.halfRow(
      panel.new(title='Franchise')
      .addTargets([paymentsSLATarget()])
    ) { type: 'gauge' },
    panel.halfRow(
      panel.new(title='OPS')
      .addTargets([opsSLATarget()])
    ) { type: 'gauge' },
  ]),
])

.addRows([
  row.new('Payments Questbox').addPanels([
    panel.halfRow(
      panel.new(title='Payments')
      .addTargets([paymentsSLATarget()])
    ) { type: 'gauge' },
    panel.halfRow(
      panel.new(title='Questbox')
      .addTargets([questboxSLATarget()])
    ) { type: 'gauge' },
  ]),
])
