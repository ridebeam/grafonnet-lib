local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local k8s_helper = import '../k8s.libsonnet';

local k8s = k8s_helper.init('ridebeam-payments');

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'GCP Go Service (payments)',
  uid='gcp-go-service-core',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['overview', 'generic', 'generated'],
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
    query='iot-server,vehicle-controller,vehicle-gateway,payment-service,trip,settings,user-authz',
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
