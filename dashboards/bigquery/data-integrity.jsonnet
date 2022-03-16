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
    partitionRowCount: target.gauge(
      metric='bq-row-diff-partition-tables',
      groupBys=['table_id'],
      includeZero=true,
      gaugeFunc=target.gaugeFuncs.max,
    ),
    partitionRowCountBimonthly: target.gauge(
      metric='bq-row-diff-partition-tables-bimonthly',
      groupBys=['table_id'],
      includeZero=true,
      gaugeFunc=target.gaugeFuncs.max,
    ),
  },
  mutations: target.gauges(metric='bq_mutations', groupBys=['table_id'], filters=target.equalsFilter('table_id', '$bq_table_id')).sum,
  mutationsHourly: target.gauges(metric='bq_mutations_hourly', groupBys=['hour'], filters=target.equalsFilter('table_id', '$bq_table_id')).sum {
    format: 'table',
    instant: true,
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
    partitionRowCount: panel.new('Partition row count difference').addTargets([
      targets.dataCompleteness.partitionRowCount,
    ]),
    partitionRowCountBimonthly: panel.new('Partition row count difference - 2 months').addTargets([
      targets.dataCompleteness.partitionRowCountBimonthly,
    ]),
  },
  mutations: panel.new('Total number of mutations for ${bq_table_id}').addTargets([targets.mutations]),
  mutationsHourly: panel.new('Hourly mutations for ${bq_table_id}').addTargets([targets.mutationsHourly]) + {
    transformations: [
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
          },
          indexByName: {},
          renameByName: {},
        },
      },
    ],
    type: 'barchart',
  },
};

local rows = {
  tableSize: row.new('Tables Size').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.tableSize,
      panels.general.zeroByte,
    ]
  ]),

  snapshot: row.new('Snapshots').addPanels([
    panel.fullRow(p)
    for p in [
      panels.dataCompleteness.snapshotRowCount,
    ]
  ]),


  partition: row.new('Partitions').addPanels([
    panel.fullRow(p)
    for p in [
      panels.dataCompleteness.partitionRowCount,
      panels.dataCompleteness.partitionRowCountBimonthly,
    ]
  ]),

  etl: row.new('ETL - Scheduled Queries').addPanels([
    panel.fullRow(p)
    for p in [
      panels.general.scheduledQueries,
    ]
  ]),

  mutations: row.new('Mutations of ${bq_table_id}', repeat='bq_table_id', collapse=true).addPanels([
    panel.halfRow(p)
    for p in [
      panels.mutations,
      panels.mutationsHourly,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'BQ Data Integrity',
  uid='bq-data-integrity',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
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

.addTemplate(
  template.new(
    name='bq_table_id',
    datasource=null,
    query='label_values(bq_mutations_hourly, table_id)',
    current='$__all',
    multi=true,
    includeAll=true,
    refresh=1,
    sort=1,
    hide='variable',
  )
)

.addRows([
  rows.tableSize,
  rows.snapshot,
  rows.partition,
  rows.mutations,
  rows.etl,
])
