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
  'victoriametrics-agent',
  uid='monitoring_victoriametrics-agent',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.new(
    name='cluster',
    datasource=null,
    query='label_values(process_cpu_seconds_total, cluster)',
    current='$__all',
    multi=true,
    includeAll=true,
    refresh=1,
    sort=1,
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='victoriametrics-agent',
    current='victoriametrics-agent',
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
          filters=target.combineFilters(target.equalsFilter('container', '$service'), target.likeFilter('cluster', '$cluster')),
          groupBys=['cluster'],
          withServiceFilters=false,
          intervalFactor=2,
        )
      ),
      panel.new('Memory Usage', format='bytes', legend_show=true).addTarget(
        target.gauges(
          metric='container_memory_usage_bytes',
          filters=target.combineFilters(target.equalsFilter('container', '$service'), target.likeFilter('cluster', '$cluster')),
          groupBys=['cluster'],
          withServiceFilters=false,
          intervalFactor=2,
        ).max
      ),
      panel.new('Log Output (aprox entries per minute)', legend_show=true).addTarget(
        libProm.target(
          'sum(avg_over_time(stackdriver_k_8_s_container_logging_googleapis_com_log_entry_count{container_name="$service", cluster_name=~"$cluster"}[$__interval])) by (cluster) > 0',
          legendFormat='{{cluster}}',
        )
      ),
    ]
  ]),
])
