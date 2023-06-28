local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local k8s = import '../k8s-promql.libsonnet';


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'payment-inicis-pg-bridge',
  uid='payments_payment-inicis-pg-bridge',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
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
    query='inicis-pg-bridge',
    current='inicis-pg-bridge',
    hide='variable',
  )
)

.addRows(
  [
    k8s.rows.service,
  ]
)
