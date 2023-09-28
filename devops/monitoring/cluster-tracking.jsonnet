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
  'k8s-cluster-monitoring',
  uid='monitoring_k8s_cluster',
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
.addTemplate(
  template.custom(
    name='spot_cpu_price_hourly',
    query='0.009747',
    current='0.009747',
    hide='variable',
  )
)
.addTemplate(
  template.custom(
    name='spot_ram_price_hourly',
    query='0.001306',
    current='0.001306',
    hide='variable',
  )
)


.addRows([
  row.new('Cluster Resources').addPanels([
    panel.halfRow(p)
    for p in [
      graphPanel.new('VM Monthly Cost By Service', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, format='currencyUSD').addTarget(
        libProm.target(
          'sum(kube_pod_container_resource_requests{cluster="$cluster", resource="cpu"}) by (container) * $cpu_price_hourly * 730 + sum(kube_pod_container_resource_requests{cluster="$cluster", resource="memory"}) by (container) /1024/1024/1024 * $ram_price_hourly * 730',
          legendFormat='{{container}}',
        )
      ),
      graphPanel.new('VM Monthly Cost', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, format='currencyUSD').addTarget(
        libProm.target(
          'sum(kube_node_status_capacity{cluster="$cluster", resource="cpu",node!~".*spot.*"}) by (node_name) * $cpu_price_hourly * 730 +  sum(kube_node_status_capacity{cluster="$cluster", resource="cpu",node=~".*spot.*"}) by (node_name) * $spot_cpu_price_hourly * 730',
          legendFormat='CPU',
        )
      ).addTarget(
        libProm.target(
          'sum(kube_node_status_capacity{cluster="$cluster", resource="memory",node!~".*spot.*"}) by (node_name) /1024/1024/1024 * $ram_price_hourly * 730 + sum(kube_node_status_capacity{cluster="$cluster", resource="memory",node!=".*spot.*"}) by (node_name) /1024/1024/1024 * $spot_ram_price_hourly * 730',
          legendFormat='Memory',
        )
      ) + {
        transformations: [
          {
            id: 'calculateField',
            options: {
              alias: 'Total',
              binary: {
                left: 'CPU',
                reducer: 'sum',
                right: 'Memory',
              },
              mode: 'binary',
              reduce: {
                reducer: 'sum',
              },
            },
          },
        ],
      },
    ]
  ]),
  row.new('Node Resources').addPanels([
    panel.halfRow(p)
    for p in [
      graphPanel.new('CPU Utilization (Request/Allocatable)', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='percentunit').addTarget(
        libProm.target(
          'sum(\nsum(kube_pod_container_resource_requests{cluster="$cluster", resource="cpu", node!~".*spot.*"}) by (pod,node) * on (pod) group_left(pod) label_replace (min(kube_pod_container_status_running{cluster="$cluster"}) by (pod, node_name),\n  "node",\n  "$1",\n  "node_name",\n  "(.*)"\n)) by (node)\n/\nsum(kube_node_status_allocatable{cluster="$cluster", resource="cpu", instance!~".*spot.*"}) by (node)',
          legendFormat='{{node}}',
        )
      ),
      graphPanel.new('Node Container CPU Utilization (Actual/Request)', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='percentunit').addTarget(
        libProm.target(
          'sum(label_replace(irate(container_cpu_usage_seconds_total{cluster="$cluster", container!="", node!~".*spot.*"})[$__interval],\n "node", "$1", "instance", "(.*)")) by (node)\n/ \nsum(\nsum(kube_pod_container_resource_requests{cluster="$cluster", resource="cpu", node!~".*spot.*"}) by (pod,node) * on (pod) group_left(pod) label_replace (min(kube_pod_container_status_running{cluster="$cluster"}) by (pod, node_name),\n  "node",\n  "$1",\n  "node_name",\n  "(.*)"\n)) by (node)',
          legendFormat='{{node}}',
        )
      ),
      graphPanel.new('Memory Utilization (Request/Allocatable)', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='percentunit').addTarget(
        libProm.target(
          'sum(\nsum(kube_pod_container_resource_requests{cluster="$cluster", resource="memory", node!~".*spot.*"}) by (pod,node) * on (pod) group_left(pod) label_replace (min(kube_pod_container_status_running{cluster="$cluster"}) by (pod, node_name),\n  "node",\n  "$1",\n  "node_name",\n  "(.*)"\n)) by (node)\n/\nsum(kube_node_status_allocatable{cluster="$cluster", resource="memory"}) by (node)',
          legendFormat='{{node}}',
        )
      ),
      graphPanel.new('Node Memory Utilization (Actual/Request by Container)', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='percentunit').addTarget(
        libProm.target(
          'sum(\nsum(\nlabel_replace(\n    container_memory_working_set_bytes{cluster="$cluster", container != "", node!~".*spot.*"},\n    "node",\n    "$1",\n    "instance",\n    "(.*)"\n  )\n) by (pod,node) \nAND on(pod, node)\ncount(sum(kube_pod_container_resource_requests{cluster="$cluster", resource="memory", node!~".*spot.*"}) by (pod, node)) by (pod,node) * on (pod) group_left(pod) label_replace (min(kube_pod_container_status_running{cluster="$cluster"}) by (pod, node_name),\n  "node",\n  "$1",\n  "node_name",\n  "(.*)")\n) by (node)\n/ \nsum(\nsum(kube_pod_container_resource_requests{cluster="$cluster", resource="memory"}) by (pod,node) * on (pod) group_left(pod) label_replace (min(kube_pod_container_status_running{cluster="$cluster"}) by (pod, node_name),\n  "node",\n  "$1",\n  "node_name",\n  "(.*)"\n)) by (node)',
          legendFormat='{{node}}',
        )
      ),

    ]
  ]),
  row.new('Namespace Resources').addPanels([
    panel.halfRow(p)
    for p in [
      graphPanel.new('CPU Utilization(Actual/Request) By Pod', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='percentunit').addTarget(
        libProm.target(
          'sum(irate(container_cpu_usage_seconds_total{cluster="$cluster", container != "", namespace="$namespace"})[$__interval]) by (container, namespace) / sum(container_spec_cpu_shares{cluster="$cluster",container != "", namespace="$namespace"} / 1024) by (namespace,container)',
          legendFormat='{{container}}',
        )
      ),
      graphPanel.new('Memory Utilization (Actual/Request) By Pod', fill=0, legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='percentunit').addTarget(
        libProm.target(
          ' sum(container_memory_working_set_bytes{cluster="$cluster", container != "", namespace="$namespace"}) by (container) / sum (kube_pod_container_resource_requests{cluster="$cluster", exported_namespace="$namespace", resource="memory"}) by (container)',
          legendFormat='{{container}}',
        )
      ),

    ]
  ]),
])
