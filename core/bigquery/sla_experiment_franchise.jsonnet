local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local experimentSLAQuery() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'experiment.%'
    )
    select
      SUBSTRING(table_name, 12, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local franchiseSLAQuery() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'franchise.%'
    )
    select
      SUBSTRING(table_name, 11, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
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

grafana.dashboard.new(
  'Experiment and Franchies BQ SLA',
  uid='experiment_sla',
  refresh='1d',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-90d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  row.new('Franchise').addPanels([
    panel.halfRow(
      panel.new(title='Franchise')
      .addTargets([franchiseSLATarget()])
    ) { type: 'barchart' },
  ]),
])

.addRows([
  row.new('Franchise').addPanels([
    panel.halfRow(
      panel.new(title='Experiment')
      .addTargets([experimentSLATarget()])
    ) { type: 'barchart' },
  ]),
])
