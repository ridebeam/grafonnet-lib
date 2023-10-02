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
  'Kubernetes Running Pod Per Node',
  uid='monitoring_k8s_running_pod',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)


.addRows([
  row.new('Nodes').addPanels([
    panel.fullRow(p)
    for p in [
      graphPanel.new('Staging Nodes', fill=0).addTarget(
        libProm.target(
          'kubelet_running_pods{cluster="staging-sg"}',
          legendFormat='{{instance}}',
        )
      ),
      graphPanel.new('Payment Nodes', fill=0).addTarget(
        libProm.target(
          'kubelet_running_pods{cluster="payments-sg"}',
          legendFormat='{{instance}}',
        )
      ),
      graphPanel.new('Production Nodes(Argo Workflow)', fill=0).addTarget(
        libProm.target(
          'kubelet_running_pods{cluster="core-sg",node_pool=~".*n2-12c-16m-200-ssd"}',
          legendFormat='{{instance}}',
        )
      ),
      graphPanel.new('Production Nodes(Regular Service)', fill=0).addTarget(
        libProm.target(
          'kubelet_running_pods{cluster="core-sg",node_pool="n2-16c-64m-64hdd"}',
          legendFormat='{{instance}}',
        )
      ),
    ]
  ]),
])
