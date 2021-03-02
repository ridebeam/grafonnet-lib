local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local k8s = import 'k8s.libsonnet';

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'GCP Go Service',
  uid='gcp-go-service',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['overview','generic','generated']
)

  .addTemplate(
    template.custom(
      name='env',
      query='dev,staging,production',
      current='production',
    )
  )

  .addTemplate(  
    template.custom(
      name='service',
      query='iot-server,vehicle-controller,vehicle-gateway',
      current='iot-server',
    )
  )

  .addRows([
    k8s.rows.service,
    k8s.rows.http,
    k8s.rows.grpc,
    k8s.rows.kafka,
    k8s.rows.postgres,
  ])
