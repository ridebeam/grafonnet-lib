local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local gaugePanel = grafana.gaugePanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local libProm = grafana.prometheus;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local gauge_thresholds = [
  {
    color: 'rgba(50, 172, 45, 0.97)',
    value: null,
  },
  {
    color: 'rgba(237, 129, 40, 0.89)',
    value: 65,
  },
  {
    color: 'rgba(245, 54, 54, 0.9)',
    value: 90,
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Kubernetes Node Monitoring',
  uid='monitoring_k8s_node',
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
    name='node',
    datasource='Prometheus',
    query='label_values(kube_node_info{cluster="$cluster"}, node)',
    multi=false,
    includeAll=false,
    refresh=1,
    sort=1,
  )
)

.addRows([
  row.new('Network Usage').addPanels([
    panel.fullRow(p)
    for p in [
      graphPanel.new('Network I/O pressure', format='Bps').addTarget(
        libProm.target(
          'sum (rate (container_network_receive_bytes_total{kubernetes_io_hostname=~"^$node$"}[1m]))',
          legendFormat='received',
        )
      ).addTarget(
        libProm.target(
          '- sum (rate (container_network_transmit_bytes_total{kubernetes_io_hostname=~"^$node$"}[1m]))',
          legendFormat='sent',
        )
      ),
    ]
  ]),
  row.new('Node Resources')
  .addPanel(
    gaugePanel.new('Node Memory Usage').addTarget(
      libProm.target(
        'sum (container_memory_working_set_bytes{id="/",kubernetes_io_hostname=~"^$node$"}) / sum (machine_memory_bytes{kubernetes_io_hostname=~"^$node$"}) * 100',
      )
    ).addThresholds(gauge_thresholds)
  )
  .addPanel(
    gaugePanel.new('Node Memory Request').addTarget(
      libProm.target(
        'sum (kube_pod_container_resource_requests{resource="memory", node=~"^$node$"})/ sum (machine_memory_bytes{kubernetes_io_hostname=~"^$node$"}) * 100',
      )
    ).addThresholds(gauge_thresholds)
  )
  .addPanel(
    gaugePanel.new('Node CPU Usage(1m avg)').addTarget(
      libProm.target(
        'sum (rate (container_cpu_usage_seconds_total{id="/",kubernetes_io_hostname=~"^$node$"}[1m])) / sum (machine_cpu_cores{kubernetes_io_hostname=~"^$node$"}) * 100',
      )
    ).addThresholds(gauge_thresholds)
  )
  .addPanel(
    gaugePanel.new('Node CPU Request(1m avg)').addTarget(
      libProm.target(
        'sum (kube_pod_container_resource_requests{resource="cpu", node=~"^$node$"}) / sum (machine_cpu_cores{kubernetes_io_hostname=~"^$node$"}) * 100',
      )
    ).addThresholds(gauge_thresholds)
  )
  .addPanel(
    gaugePanel.new('Node Filesystem Usage').addTarget(
      libProm.target(
        'sum (container_fs_usage_bytes{device=~"^/dev/[sv]d[a-z][1-9]$",id="/",kubernetes_io_hostname=~"^$node$"}) / sum (container_fs_limit_bytes{device=~"^/dev/[sv]d[a-z][1-9]$",id="/",kubernetes_io_hostname=~"^$node$"}) * 100',
      )
    ).addThresholds(gauge_thresholds)
  ),
  row.new('Node(Pod) Resource').addPanels([
    panel.fullRow(p)
    for p in [
      graphPanel.new('Pods CPU usage', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='none').addTarget(
        libProm.target(
          'sum (rate (container_cpu_usage_seconds_total{image!="",kubernetes_io_hostname=~"^$node$"}[1m])) by (pod)',
          legendFormat='{{pod}}',
        )
      ),
      graphPanel.new('Pods Memory usage', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='bytes').addTarget(
        libProm.target(
          'sum (container_memory_working_set_bytes{image!="",kubernetes_io_hostname=~"^$node$"}) by (pod)',
          legendFormat='{{pod}}',
        )
      ),
      graphPanel.new('Pods Network usage', legend_values=true, legend_show=true, legend_alignAsTable=true, legend_rightSide=true, legend_current=true, legend_avg=true, format='Bps').addTarget(
        libProm.target(
          'sum (rate (container_network_receive_bytes_total{image!="",kubernetes_io_hostname=~"^$node$"}[1m])) by (pod)',
          legendFormat='-> {{pod}}',
        )
      ).addTarget(
        libProm.target(
          '- sum (rate (container_network_transmit_bytes_total{image!="",kubernetes_io_hostname=~"^$node$"}[1m])) by (pod)',
          legendFormat='<- {{pod}}',
        )
      ),
    ]
  ]),
])
