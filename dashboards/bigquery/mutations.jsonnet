local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;


local targets = {
  mutations: target.gauges(metric='bq_mutations', groupBys=['table_id'], filters=target.equalsFilter('table_id', '$bq_table_id')).sum,
  mutationsHourly: target.gauges(metric='bq_mutations_hourly', groupBys=['hour'], filters=target.equalsFilter('table_id', '$bq_table_id')).sum + {
    format: "table",
    instant: true
  }
};

local panels = {
  mutations: panel.new('Total number of mutations for ${bq_table_id}').addTargets([targets.mutations]),
  mutationsHourly: panel.new('Hourly mutations for ${bq_table_id}').addTargets([targets.mutationsHourly]) + {
                      "transformations": [
                          {
                            "id": "organize",
                            "options": {
                              "excludeByName": {
                                "Time": true
                              },
                              "indexByName": {},
                              "renameByName": {}
                            }
                          }
                        ],
                        "type": "barchart"
                    },
};

local rows = {
  general: row.new('BQ ${bq_table_id}', repeat='bq_table_id').addPanels([
    panel.halfRow(p)
    for p in [
      panels.mutations,
      panels.mutationsHourly
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'BigQuery mutations',
  uid='bq-mutations',
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
])
