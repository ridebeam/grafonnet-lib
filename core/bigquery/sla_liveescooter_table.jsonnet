local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local liveescooterSLAQuery1() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.credittransactions',
          'liveescooter.currencies',
          'liveescooter.authorisedates',
          'liveescooter.userevents',
          'liveescooter.adyentransactions',
          'liveescooter.payouts'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery2() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.vehiclealarmevents',
          'liveescooter.tripvehiclelockstates',
          'liveescooter.adminauthcodes',
          'liveescooter.vehiclewattages',
          'liveescooter.parkingspotsschedules'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery3() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.inipayauths',
          'liveescooter.adyenauths',
          'liveescooter.businessprofiles',
          'liveescooter.parkingreportedissues',
          'liveescooter.uservehiclecharges'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery4() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.cost_centers',
          'liveescooter.nearbyvehicles',
          'liveescooter.noncredittransactions'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery5() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.georegionsubscriptions',
          'liveescooter.taskconfigurations',
          'liveescooter.businessusers',
          'liveescooter.corporateusers',
          'liveescooter.interstitials',
          'liveescooter.accounts'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery6() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.subscriptionplans',
          'liveescooter.roles',
          'liveescooter.warehouses',
          'liveescooter.rentals',
          'liveescooter.towingfines',
          'liveescooter.adhoccharges'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery7() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.userroles',
          'liveescooter.promocodecampaigns',
          'liveescooter.tripinvoices',
          'liveescooter.liveescooter__user_promo_code_redeems',
          'liveescooter.batteryevents',
          'liveescooter.endtripphotoaudits'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery8() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.vehiclesettings',
          'liveescooter.userregistrations',
          'liveescooter.userreferralrecords',
          'liveescooter.vehiclesummaries',
          'liveescooter.vehiclereportedissues',
          'liveescooter.businesstrips'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery9() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.safeacademyquizresults',
          'liveescooter.vehiclebatteries',
          'liveescooter.vehiclessettings',
          'liveescooter.accountactionlogs',
          'liveescooter.idealscooterlocations',
          'liveescooter.tasks'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery10() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.vehicles',
          'liveescooter.triproutes',
          'liveescooter.adminactionlogs',
          'liveescooter.trips',
          'liveescooter.vehiclestatuschanges',
          'liveescooter.promocodes'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery11() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.vehiclerepairs',
          'liveescooter.omnierrorreports',
          'liveescooter.vehiclesnapshots',
          'liveescooter.creditaccounts',
          'liveescooter.documents',
          'liveescooter.helmetlocks'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery12() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.users',
          'liveescooter.userrefreshtokens',
          'liveescooter.vehiclephonelocations',
          'liveescooter.guestusers',
          'liveescooter.vehicleevents',
          'liveescooter.georegions'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery13() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.emailverificationtokens',
          'liveescooter.userpromocoderedeems',
          'liveescooter.usersubscriptiontriprewards',
          'liveescooter.fines',
          'liveescooter.admin_users',
          'liveescooter.userpromocodeclaims'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLAQuery14() =
  |||
    with cte as (
      SELECT
        table_name,  
        toUInt32(created_at)*1000,
        freshness_in_minutes,
        if(freshness_in_minutes <= 60*24,1,0) as ok
      FROM analytics_watchdog.bigquery_freshness
        WHERE $timeFilter
        AND table_name like 'liveescooter.%'
        AND table_name in [
          'liveescooter.creditpackpurchases',
          'liveescooter.usersubscriptions'
        ]
    )
    select
      SUBSTRING(table_name, 14, 100),
      100*sum(ok)/count(table_name) as pct
    from cte
    group by table_name
    order by pct
  |||
;

local liveescooterSLATarget1() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery1(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget2() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery2(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget3() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery3(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget4() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery4(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget5() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery5(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget6() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery6(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget7() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery7(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget8() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery8(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget9() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery9(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget10() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery10(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget11() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery11(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget12() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery12(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget13() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery13(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

local liveescooterSLATarget14() =
  target.target(
    database='analytics_watchdog',
    datasourceUID=clickhouse.dataSourceUIDProd,
    dateTimeColDataType='created_at',
    query=liveescooterSLAQuery14(),
    table='bigquery_freshness',
  ) {
    format: 'table',
  }
;

grafana.dashboard.new(
  'Liveescooter BQ SLA',
  uid='live_escooter_sla',
  refresh='1d',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-90d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  row.new('Liveescooter').addPanels([
    panel.halfRow(
      panel.new(title='Liveescooter 1')
      .addTargets([liveescooterSLATarget1()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 2')
      .addTargets([liveescooterSLATarget2()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 3')
      .addTargets([liveescooterSLATarget3()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 4')
      .addTargets([liveescooterSLATarget4()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 5')
      .addTargets([liveescooterSLATarget5()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 6')
      .addTargets([liveescooterSLATarget6()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 7')
      .addTargets([liveescooterSLATarget7()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 8')
      .addTargets([liveescooterSLATarget8()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 9')
      .addTargets([liveescooterSLATarget9()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 10')
      .addTargets([liveescooterSLATarget10()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 11')
      .addTargets([liveescooterSLATarget11()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 12')
      .addTargets([liveescooterSLATarget12()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 13')
      .addTargets([liveescooterSLATarget13()])
    ) { type: 'barchart' },
    panel.halfRow(
      panel.new(title='Liveescooter 14')
      .addTargets([liveescooterSLATarget14()])
    ) { type: 'barchart' },
  ]),
])
