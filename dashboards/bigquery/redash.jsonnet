local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local libProm = grafana.prometheus;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'redash',
  uid='bigquery_redash',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='service',
    query='redash-server',
    current='redash-server',
    hide='variable',
  )
)

.addRows([
  row.new('Service Overview').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLinear('CPU Usage', legend_show=true).addTarget(
        target.counter(
          metric='container_cpu_usage_seconds_total',
          filters=target.likeFilter('container', 'redash-.+'),
          groupBys=['container'],
          withServiceFilters=false,
        )
      ),
      panel.new('Memory Usage', format='bytes', legend_show=true).addTarget(
        target.gauge(
          metric='container_memory_usage_bytes',
          filters=target.likeFilter('container', 'redash-.+'),
          groupBys=['container'],
          gaugeFunc=target.gaugeFuncs.sum,
          withServiceFilters=false,
        )
      ),
      panel.new('Memory Usage Workers', format='bytes', legend_show=true).addTargets([
        target.gauge(
          metric='container_memory_usage_bytes',
          filters=target.equalsFilter('container', 'redash-adhoc-worker'),
          groupBys=['pod'],
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
        target.gauge(
          metric='container_memory_usage_bytes',
          filters=target.equalsFilter('container', 'redash-scheduled-worker'),
          groupBys=['pod'],
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
      ]),
      panel.new('Log Output (aprox entries per minute)', legend_show=true).addTarget(
        libProm.target(
          'sum(avg_over_time(stackdriver_k_8_s_container_logging_googleapis_com_log_entry_count{container_name=~"redash-.+"}[$__interval])) by (container_name) > 0',
          legendFormat='{{container_name}}',
        )
      ),
    ]
  ]),
  row.new('Queries').addPanels([
    panel.halfRow(p)
    for p in [
      panel.new('Total', legend_show=false).addTarget(
        target.gauges(
          metric='redash_queries_count',
          withServiceFilters=false,
        ).max
      ),
      panel.new('Results', legend_show=false).addTarget(
        target.gauges(
          metric='redash_query_results_count',
          withServiceFilters=false,
        ).max
      ),
      panel.new('Unused Results', legend_show=false).addTarget(
        target.gauges(
          metric='redash_unused_query_results_count',
          withServiceFilters=false,
        ).max
      ),
      panel.new('Outdated Results', legend_show=false).addTarget(
        target.gauges(
          metric='redash_outdated_queries_count',
          withServiceFilters=false,
        ).max
      ),
      panel.new('Queues', legend_show=true).addTargets([
        target.gauge(
          metric='redash_queues_queries',
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
        target.gauge(
          metric='redash_queues_scheduled_queries',
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
        target.gauge(
          metric='redash_queues_schemas',
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
        target.gauge(
          metric='redash_queues_emails',
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
        target.gauge(
          metric='redash_queues_periodic',
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
        target.gauge(
          metric='redash_queues_default',
          gaugeFunc=target.gaugeFuncs.max,
          withServiceFilters=false,
        ),
      ]),
    ]
  ]),
  row.new('Content').addPanels([
    panel.halfRow(p)
    for p in [
      panel.new('Widgets', legend_show=false).addTarget(
        target.gauges(
          metric='redash_wigets_count',
          withServiceFilters=false,
        ).max
      ),
      panel.new('Dashboards', legend_show=false).addTarget(
        target.gauges(
          metric='redash_dashboards_count',
          withServiceFilters=false,
        ).max
      ),
    ]
  ]),
  row.new('Storage').addPanels([
    panel.halfRow(p)
    for p in [
      panel.new('Database Disk Usage', legend_show=false, format='bytes').addTarget(
        target.gauges(
          metric='redash_db_size_bytes',
          withServiceFilters=false,
        ).max
      ),
      panel.new('Redis Memory Usage', legend_show=false, format='bytes').addTarget(
        target.gauges(
          metric='redash_redis_used_memory_bytes',
          withServiceFilters=false,
        ).max
      ),
      panel.new('Results Storage', legend_show=false, format='bytes').addTarget(
        target.gauges(
          metric='redash_query_results_size_bytes',
          withServiceFilters=false,
        ).max
      ),
    ]
  ]),
])
