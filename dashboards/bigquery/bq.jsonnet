local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local lcdGauge = import '../../helper/lcd-gauge.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  general: {
    zeroByte: target.counter(
      metric='bq-zero-byte-table',
      includeZero=true
    ),
    tableSize: target.gauge(
      metric='bq-table-size',
      includeZero=true,
      groupBys=['table_id'],
      gaugeFunc=target.gaugeFuncs.sum,
    ) + {
      format: 'table',
      instant: true,
    },
    scheduledQueries: target.gauges(metric='bq_scheduled_query', groupBys=['scheduled_query_state']).sum,
  },
  dataCompleteness: {
    snapshotRowCount: target.gauge(
      metric='bq-row-diff-snapshot-tables',
      groupBys=['table_id'],
      includeZero=true,
      gaugeFunc=target.gaugeFuncs.max,
    ),
  },
  serviceUptime: {
    queryLatency: target.timers(
      metric='bq-query-latency',
      groupBys=['query_id'],
    ),
  },
};

local panels = {
  general: {
    zeroByte: panel.counter('Number of tables with zero bytes').addTargets([targets.general.zeroByte]),
    tableSize: panel.new('Size of tables').addTargets([targets.general.tableSize]) + lcdGauge.new(key='table_id', value='bytes', unit='decbytes'),
    scheduledQueries: panel.new('Scheduled queries state').addTargets([targets.general.scheduledQueries]),
  },
  dataCompleteness: {
    snapshotRowCount: panel.new('Snapshot row count difference').addTargets([
      targets.dataCompleteness.snapshotRowCount,
    ]),
  },
  serviceUptime: {
    queryLatencyP50: panel.timeLog2('Query latency P50').addTargets([
      targets.serviceUptime.queryLatency.p50,
    ]),
    queryLatencyP99: panel.timeLog2('Query latency P99').addTargets([
      targets.serviceUptime.queryLatency.p99,
    ]),
  },
};

local rows = {
  general: row.new('General').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.zeroByte,
      panels.general.tableSize,
      panels.general.scheduledQueries,
    ]
  ]),
  dataCompleteness: row.new('Data Completeness').addPanels([
    panel.halfRow(p)
    for p in [
      panels.dataCompleteness.snapshotRowCount,
    ]
  ]),
  serviceUptime: row.new('Service Uptime').addPanels([
    panel.halfRow(p)
    for p in [
      panels.serviceUptime.queryLatencyP50,
      panels.serviceUptime.queryLatencyP99,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'bigquery monitoring',
  uid='bq',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='analytics-watchdog',
    current='analytics-watchdog',
    hide='variable',
  )
)

.addRows([
  rows.general,
  rows.dataCompleteness,
  rows.serviceUptime,
])
