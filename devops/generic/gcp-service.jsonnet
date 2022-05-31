local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local k8s = import '../k8s-promql.libsonnet';

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'GCP Service',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['overview', 'generic', 'generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,staging,stable,production',
    current='production',
  )
)

.addTemplate(
  template.new(
    name='service',
    datasource=null,
    query='label_values(container_memory_usage_bytes, container)',
    current='api',
    refresh=1,
    sort=1,
  )
)

.addRows([
  k8s.rows.service,
  k8s.rows.http,
  k8s.rows.grpc,
  k8s.rows.kafka,
  k8s.rows.postgres,
])
