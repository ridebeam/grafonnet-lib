local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local opsSLAQuery1() =
  |||
    with cte as (
      SELECT
        table_name,  
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'ops.%'
        AND table_name in [
          'ops.qa_user',
          'ops.parking_spot_snapshot',
          'ops.vehicle_hourly_snapshots',
          'ops.vehicle_state_in_risk_unrepairable_latest_snapshot_with_confirmation',
          'ops.vehicle_state_in_risk_unrepairable_latest_snapshot'
        ]
    )
    select
      SUBSTRING(table_name, 5, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local opsSLAQuery2() =
  |||
    with cte as (
      SELECT
        table_name,  
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'ops.%'
        AND table_name in [
          'ops.vehicle_never_deployed',
          'ops.vehicle_without_trip',
          'ops.vehicle_state_in_risk_loss_latest_snapshot_with_confirmation',
          'ops.vehicle_state_in_risk_loss_latest_snapshot',
          'ops.vehicle'
        ]
    )
    select
      SUBSTRING(table_name, 5, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local opsSLAQuery3() =
  |||
    with cte as (
      SELECT
        table_name,  
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'ops.%'
        AND table_name in [
          'ops.parking_spot',
          'ops.region_tree',
          'ops.region',
          'ops.admin_consolidated',
          'ops.consolidated_tasks'
        ]
    )
    select
      SUBSTRING(table_name, 5, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local opsSLAQuery4() =
  |||
    with cte as (
      SELECT
        table_name,  

        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'ops.%'
        AND table_name in [
          'ops.region_tree_snapshot',
          'ops.vehicle_event',
          'ops.vehicle_event_latest',
          'ops.consolidated_admins',
          'ops.vehicle_event_release',
          'ops.ops__consolidated_admins',
          'ops.parking_spot_hourly_snapshots'
        ]
    )
    select
      SUBSTRING(table_name, 5, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local opsSLATarget1() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=opsSLAQuery1(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local opsSLATarget2() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=opsSLAQuery2(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local opsSLATarget3() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=opsSLAQuery3(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local opsSLATarget4() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=opsSLAQuery4(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

grafana.dashboard.new(
  'OPS BQ SLA',
  uid='ops_sla',
  refresh='1d',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-90d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  row.new('ops').addPanels([
    panel.halfRow(
      panel.new(title='ops 1')
      .addTargets([opsSLATarget1()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='ops 2')
      .addTargets([opsSLATarget2()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='ops 3')
      .addTargets([opsSLATarget3()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='ops 4')
      .addTargets([opsSLATarget4()])
    ) { type: 'barchart' },
  ]),
])
