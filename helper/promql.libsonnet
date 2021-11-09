local panel = import 'panel.libsonnet';
local target = import 'promql-target.libsonnet';

{
  init():: {
    target: target,
    panel: panel.init('Prometheus'),
  },
}
