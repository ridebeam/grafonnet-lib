local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local alertCondition = grafana.alertCondition;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;
local alerts = import '../../helper/alerts.libsonnet';
local alertsHelper = import '../../helper/alerts.libsonnet';

local percentageEtlTablesFreshnessQuery() = 
    |||
        WITH
        latest AS (
            SELECT * EXCEPT(_rn) FROM (
                SELECT
                    *,
                    multiIf( -- double of the schedule frequency due to DP-1250
                        tags='quarter_hourly', 30, 
                        tags='hourly', 120, 
                        tags='quarter_daily', 720, 
                        tags='daily', 2880, 
                        tags='kr_daily_at_12pm', 2880, 
                        tags='weekly', 20160, 
                        tags='monthly', 87840, 
                        0
                    ) AS maximum_allowed_minutes,
                    ROW_NUMBER() OVER (
                        PARTITION BY table_name, dependency_table_name
                        ORDER BY created_at DESC
                    ) AS _rn
                FROM
                    analytics_watchdog.bigquery_etl_freshness
                WHERE $timeFilter
                AND schema in ($schema)
            ) WHERE _rn = 1
        ),
        ex AS (
            SELECT *,
                ROUND((freshness_in_minutes - maximum_allowed_minutes) / maximum_allowed_minutes * 100, 0) AS over_pct
            FROM latest
        )
        SELECT
            substring(table_name, 10, 100) AS model,
            schema as schema, 
            substring(dependency_table_name, 10, 100) AS dependency_model,
            if(over_pct>=0, over_pct, 0) AS `Over SLA [%]`,
            freshness_in_minutes AS freshness_minutes,
            maximum_allowed_minutes AS sla_minutes,
            tags AS schedule,
            created_at AS created_at_utc
        FROM ex
        ORDER BY over_pct DESC
    |||
;

local percentageEtlTablesFreshnessTarget() =
    target.target(
        database='analytics_watchdog',
        datasourceUID=clickhouse.dataSourceUIDProd,
        dateTimeColDataType='created_at',
        query=percentageEtlTablesFreshnessQuery(),
        table='bigquery_etl_freshness',
    ) {
        format: 'table',
    }
;

local percentageEtlTablesFreshnessWithTimeQuery() = 
    |||
        WITH
        latest AS (
            SELECT * EXCEPT(_rn) FROM (
                SELECT
                    *,
                    multiIf( -- double of the schedule frequency due to DP-1250
                        tags='quarter_hourly', 30, 
                        tags='hourly', 120, 
                        tags='quarter_daily', 720, 
                        tags='daily', 2880, 
                        tags='kr_daily_at_12pm', 2880, 
                        tags='weekly', 20160, 
                        tags='monthly', 87840, 
                        0
                    ) AS maximum_allowed_minutes,
                    ROW_NUMBER() OVER (
                        PARTITION BY table_name, dependency_table_name
                        ORDER BY created_at DESC
                    ) AS _rn
                FROM
                    analytics_watchdog.bigquery_etl_freshness
                WHERE $timeFilter
                AND schema in ($schema)
            ) WHERE _rn = 1
        ),
        ex AS (
            SELECT *,
                ROUND((freshness_in_minutes - maximum_allowed_minutes) / maximum_allowed_minutes * 100, 0) AS over_pct
            FROM latest
        )
        SELECT
            toUInt32(toStartOfInterval(created_at, INTERVAL 15 minute)) * 1000 AS time,
            substring(table_name, 10, 100) AS model, 
            MAX(if(over_pct>=0, over_pct, 0)) AS `Over SLA Percentage [%]`
        FROM ex
        GROUP BY time, model
    |||
;

local percentageEtlTablesFreshnessWithTimeTarget() =
    target.target(
        database='analytics_watchdog',
        datasourceUID=clickhouse.dataSourceUIDProd,
        dateTimeColDataType='created_at',
        query=percentageEtlTablesFreshnessWithTimeQuery(),
        table='bigquery_etl_freshness',
    ) {
        format: 'timeseries',
    }
;

local allTableSLAQuery() = 
    |||
        WITH source AS (
            SELECT
                substring(table_name, 10, 100) AS model,
                created_at,
                freshness_in_minutes,
                multiIf(tags = 'quarter_hourly', 30, tags='hourly', 120, tags='quarter_daily', 720, tags='daily', 2880, tags='kr_daily_at_12pm', 2880, tags='weekly', 20160, tags='monthly', 87840, 87840) as maximum_allowed_minutes
            FROM
                analytics_watchdog.bigquery_etl_freshness
            WHERE
                $timeFilter
            AND schema in ($schema)
        ),
        filtered_data AS (
            SELECT
                model,
                toStartOfInterval(created_at, INTERVAL 15 minute) AS created_at,
                if(freshness_in_minutes <= maximum_allowed_minutes, 1, 0) AS ok
            FROM source
        ),
        grouped_results AS (
            SELECT
                model,
                if(SUM(ok) = COUNT(*), 1, 0) AS ok
            FROM filtered_data
            GROUP BY model, created_at
        )
        SELECT
            model as model,
            100*SUM(ok)/COUNT(model) AS `SLA [%]`
        FROM grouped_results
        GROUP BY model
        ORDER BY model
    |||
;

local allTableSLATarget() =
    target.target(
        database='analytics_watchdog',
        datasourceUID=clickhouse.dataSourceUIDProd,
        dateTimeColDataType='created_at',
        query=allTableSLAQuery(),
        table='bigquery_etl_freshness',
    ) {
        format: 'table',
    }
;

grafana.dashboard.new(
  'SLA of BigQuery ETL Table',
  uid='bigquery_sla_etl_table',
  refresh='15m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-1d',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addTemplate(
    template.new(
    name='schema',
    label='Schema',
    datasource='Altinity plugin for ClickHouse',
    query='SELECT DISTINCT schema FROM analytics_watchdog.bigquery_etl_freshness WHERE created_at >= toDateTime(today()-3) ORDER BY schema limit 300',
    current='All',
    multi=false,
    includeAll=true,
  )
)

.addRows([
    row.new().addPanels(
        [
            panel.fullRow(
                panel.new(title='ETL Models Freshness Over SLA minutes')
                .addTargets([percentageEtlTablesFreshnessTarget()])
            ) { type: 'table' },
            panel.fullRow(
                panel.new(title='Percentage of ETL Model Freshness over Maximum Allowed Minutes against Time')
                .addTargets([percentageEtlTablesFreshnessWithTimeTarget()])
                .addAlert(
                    name='ETL Model Freshness Has Exceeded the Maximum Allowed Minutes by 200%',
                    forDuration='30m',
                    frequency='1m',
                    message="ETL Model Freshness Has Exceeded the Maximum Allowed Minutes by 200%",
                    notifications=[alertsHelper.slackData],
                ).addConditions([{
                    type: 'query',
                    query: {
                        params: [
                            'A',
                            '5m',
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
                            200,
                        ],
                    },
                }]),
            ) { type: 'timeseries' },
            panel.fullRow(
                panel.new(title='BigQuery ETL Model SLA Percentage over selected time range')
                .addTargets([allTableSLATarget()])
            ) { type: 'table' },
        ]   
    )
])
