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
  'Kubernetes Workload Monitoring',
  uid='monitoring_k8s_workload',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.new(
    name='cluster',
    datasource='Prometheus',
    query='label_values(kubelet_node_name, cluster)',
    multi=false,
    includeAll=false,
    refresh=1,
    sort=1,
  )
)

.addTemplate(
  template.new(
    name='namespace',
    datasource='Prometheus',
    query='label_values(kube_namespace_labels{cluster="$cluster"}, exported_namespace)',
    multi=false,
    includeAll=false,
    refresh=1,
    sort=1,
  )
)
.addTemplate(
  template.new(
    name='container',
    datasource='Prometheus',
    query='label_values(kube_pod_container_info{cluster="$cluster", exported_namespace="$namespace"}, container)',
    multi=false,
    includeAll=false,
    refresh=1,
    sort=1,
  )
)
.addTemplate(
  template.custom(
    name='cpu_price_hourly',
    query='0.038999',
    current='0.038999',
    hide='variable',
  )
)
.addTemplate(
  template.custom(
    name='ram_price_hourly',
    query='0.005226',
    current='0.005226',
    hide='variable',
  )
)


.addRows([
  row.new('CPU').addPanels([
    panel.halfRow(p)
    for p in [
      graphPanel.new('CPU Usage By $container', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true).addTarget(
        libProm.target(
          'sum (kube_pod_container_resource_limits{cluster="$cluster", exported_namespace="$namespace", container="$container", resource="cpu"}) by (container)',
          legendFormat='limit',
        )
      ).addTarget(
        libProm.target(
          'sum (kube_pod_container_resource_requests{cluster="$cluster", exported_namespace="$namespace", container="$container", resource="cpu"}) by (container)',
          legendFormat='request',
        )
      ).addTarget(
        libProm.target(
          'sum(irate(container_cpu_usage_seconds_total{cluster="$cluster", container="$container", namespace="$namespace"})[$__interval]) by (container)',
          legendFormat='current',
        )
      ),
      graphPanel.new('$container - CPU Monthly Cost', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, format='currencyUSD').addTarget(
        libProm.target(
          'sum (kube_pod_container_resource_requests{cluster="$cluster", exported_namespace="$namespace", container="$container", resource="cpu"}) by (container) * $cpu_price_hourly * 730',
          legendFormat='request',
        )
      ),
      graphPanel.new('CPU Usage By pod($container)', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_avg=true, legend_max=true).addTarget(
        libProm.target(
          'sum(irate(container_cpu_usage_seconds_total{cluster="$cluster", container="$container", namespace="$namespace"}[30s])) by (id,pod)',
          legendFormat='{{pod}}',
        )
      ),
    ]
  ]),
  row.new('Memory').addPanels([
    panel.halfRow(p)
    for p in [
      graphPanel.new('Memory Usage By $container', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, format='bytes').addTarget(
        libProm.target(
          'sum (kube_pod_container_resource_limits{cluster="$cluster", exported_namespace="$namespace", container="$container", resource="memory"}) by (container)',
          legendFormat='limit',
        )
      ).addTarget(
        libProm.target(
          'sum (kube_pod_container_resource_requests{cluster="$cluster", exported_namespace="$namespace", container="$container", resource="memory"}) by (container)',
          legendFormat='request',
        )
      ).addTarget(
        libProm.target(
          'sum(container_memory_usage_bytes{cluster="$cluster",container="$container", namespace="$namespace"}) by (namespace,container)',
          legendFormat='current',
        )
      ),
      graphPanel.new('$container - Memory Monthly Cost', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, format='currencyUSD').addTarget(
        libProm.target(
          'sum (kube_pod_container_resource_requests{cluster="$cluster", exported_namespace="$namespace", container="$container", resource="memory"}) by (container) /1024/1024/1024 * $ram_price_hourly * 730',
          legendFormat='request',
        )
      ),
      graphPanel.new('Memory Usage By pod($container)', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_avg=true, legend_max=true, format='bytes').addTarget(
        libProm.target(
          'container_memory_usage_bytes{cluster="$cluster",container="$container", namespace="$namespace"}',
          legendFormat='{{pod}}',
        )
      ),
    ]
  ]),

])
