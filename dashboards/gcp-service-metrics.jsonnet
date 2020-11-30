local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local k8s = import 'k8s.libsonnet';

// Make sure uid matches the name of the file
grafana.dashboard.new('GCP Service Metrics', uid='gcp-service-metrics')
  .addTemplate(  
    template.custom(
      query='dev,staging,production',
      current='production',
      name='env',
    )
  )

  .addTemplate(  
    template.custom(
      query='iot-server,vehicle-controller',
      current='iot-server',
      name='service',
    )
  )

  .addRows([
    k8s.rows.service,
    k8s.rows.http,
    k8s.rows.kafka,
    k8s.rows.postgres,
  ])
