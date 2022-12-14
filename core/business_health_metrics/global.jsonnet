local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local jwebb = import '../../helper/jwebb.libsonnet';
local vizHelper = import '../../helper/viz.libsonnet';
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

// Add metrics here
local metrics = [
  {
    name: 'trips',
    title: 'Trip Starts',
    query: 'select 1 as city_id, time_bucket, count from jwebb.trips_count_global where $timeFilter order by time_bucket asc',
  },
];

local alertsGlobalQuery(metric) =
  |||
    SELECT
        countIf(false_negative = 0) as alerts,
        countIf(false_positive = 1) as false_positives,
        countIf(false_negative = 1) as false_negatives
    FROM $table
    WHERE metric = '%(metric)s'
    AND $timeFilter
  ||| % { metric: metric.name }
;

local alertsGlobalTarget(metric) =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=alertsGlobalQuery(metric),
    table='alerts_global',
    dateTimeColDataType='time_bucket',
  ) {
    format: 'table',
  }
;

local alertOverrides = [
  vizHelper.fieldOverride('alerts', {
    displayName: 'Alerts',
    color: {
      mode: 'fixed',
      fixedColor: 'text',
    },
  }),
  vizHelper.fieldOverride('false_positives', {
    displayName: 'False positives',
    color: {
      mode: 'fixed',
      fixedColor: 'text',
    },
  }),
  vizHelper.fieldOverride('false_negatives', {
    displayName: 'False negatives',
    color: {
      mode: 'fixed',
      fixedColor: 'text',
    },
  }),
];

local alertsPanel(metric) =
  panel.halfRow(
    panel.new(title='Alerts')
    .addTargets([alertsGlobalTarget(metric)])
    .addOverrides(alertOverrides)
  ) { type: 'stat' }
;

local rows = [
  row.new(metric.title).addPanels([
    jwebb.newPanel(metric, '1', coverage=0.9999),
    alertsPanel(metric),
  ])
  for metric in metrics
];

grafana.dashboard.new(
  'Global Metrics',
  uid='global',
  refresh='15m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now+2d',
  tags=['generated'],
  editable=true,
)

.addRows(rows) {
  annotations: {
    list: [
      {
        builtIn: 1,
        datasource: {
          type: 'grafana',
          uid: '-- Grafana --',
        },
        enable: true,
        hide: true,
        iconColor: 'red',
        name: 'Annotations & Alerts',
        target: {
          limit: 100,
          matchAny: false,
          tags: [
            'alert',
            'metric:trips',
            'type:global',
          ],
          type: 'tags',
        },
        type: 'dashboard',
      },
      {
        datasource: {
          type: 'vertamedia-clickhouse-datasource',
          uid: '_Az-rRXnz',
        },
        enable: true,
        hide: true,
        iconColor: 'blue',
        name: 'Now',
        query: "select toUInt32(toStartOfInterval(now(), INTERVAL 30 minute))*1000 as time, 'Now' as text",
      },
      {
        datasource: {
          type: 'datasource',
          uid: 'grafana',
        },
        enable: true,
        hide: true,
        iconColor: 'purple',
        name: 'Deployment',
        query: 'SELECT\n  toUInt32(ts) * 1000 AS time,\n  description AS text,\n  tags\nFROM\n  event_table\nWHERE\n  ts >= toDateTime($from) AND ts < toDateTime($to)\n',
        target: {
          limit: 100,
          matchAny: false,
          tags: [
            'app-sync-succeeded',
          ],
          type: 'tags',
        },
      },
    ],
  },
}
