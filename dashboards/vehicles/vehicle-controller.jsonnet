local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local filters = {
  manufacturer: target.likeFilter('manufacturer', '$manufacturer'),
};

local targets = {
  georegion: {
    switches: target.counter(
      alias='switches',
      metric='georegion-switch',
    ),
    global: target.counter(
      alias='global',
      metric='georegion-global',
    ),
    country: target.counter(
      alias='country',
      metric='georegion-country',
    ),
    city: target.counter(
      alias='city',
      metric='georegion-city',
    ),
    geofence: target.counter(
      alias='geofence',
      metric='georegion-geofence',
    ),
  },
  state: {
    processingTime: target.timers(
      metric='kafka-consume-duration',
      filters=target.equalsFilter('kafka_source_topic', 'vehicle-state'),
    ),
    flushes: target.timers('flush-duration'),
    flushAmount: target.gauges('vehicle-repository-flush-amount'),
    changeTime: target.timers(
      metric='state-changed-latency',
      groupBys=['state_name'],
    ),
    changes: target.counter(
      metric='state-changed',
      groupBys=['state_name'],
    ),
    changeErrors: target.counter(
      metric='state-changed-error',
      groupBys=['state_name'],
    ),
  },
  vehicles: {
    disconnects: target.counter(
      metric='iot-disconnected',
      groupBys=['city_id'],
    ),
    reconnects: target.counter(
      metric='iot-disconnected-dead-connection',
      groupBys=['city_id'],
    ),
    disconnectDuration: target.timers(
      metric='iot-disconnected-duration',
      groupBys=['city_id'],
    ),
  },
};

local panels = {
  georegion: {
    switches: panel.counter('GeoRegion changes').addTargets([
      targets.georegion.switches,
    ]),
    determined: panel.counter('GeoRegion determined').addTargets([
      targets.georegion.global,
      targets.georegion.country,
      targets.georegion.city,
      targets.georegion.geofence,
    ]),
  },
  state: {
    processingTime: panel.timeLinear('Processing Time').addTargets([
      targets.state.processingTime.p50,
      targets.state.processingTime.p99,
    ]),
    flushes: panel.timeLinear('Full Flush duration').addTargets([
      targets.state.flushes.p50,
      targets.state.flushes.p99,
    ]),
    flushAmount: panel.new('Full Flush Entries').addTargets([
      targets.state.flushAmount.avg,
      targets.state.flushAmount.max,
    ]),
    changeTimeP50: panel.timeLog2('Latency p50').addTargets([
      targets.state.changeTime.p50,
    ]),
    changeTimeP99: panel.timeLog2('Latency p99').addTargets([
      targets.state.changeTime.p99,
    ]),
    changes: panel.counter('Changes').addTargets([
      targets.state.changes,
    ]),
    changeErrors: panel.counter('Errors').addTargets([
      targets.state.changeErrors,
    ]),
  },
  vehicles: {
    disconnects: panel.counter('Disconnects').addTargets([
      targets.vehicles.disconnects,
    ]),
    reconnects: panel.counter('Disconnects with Dead Connection').addTargets([
      targets.vehicles.reconnects,
    ]),
    disconnectDurationP50: panel.timeLinear('Time Disconnected p50').addTargets([
      targets.vehicles.disconnectDuration.p50,
    ]),
    disconnectDurationP99: panel.timeLinear('Time Disconnected p99').addTargets([
      targets.vehicles.disconnectDuration.p99,
    ]),
  },
};

local rows = {
  georegion: row.new('GeoRegion').addPanels([
    panel.halfRow(p)
    for p in [
      panels.georegion.switches,
      panels.georegion.determined,
    ]
  ]),
  state: row.new('State').addPanels([
    panel.thirdRow(p)
    for p in [
      panels.state.processingTime,
      panels.state.flushes,
      panels.state.flushAmount,
    ]
  ] + [
    panel.halfRow(p)
    for p in [
      panels.state.changeTimeP50,
      panels.state.changes,
      panels.state.changeTimeP99,
      panels.state.changeErrors,
    ]
  ]),
  vehicles: row.new('Vehicles').addPanels([
    panel.halfRow(p)
    for p in [
      panels.vehicles.disconnects,
      panels.vehicles.reconnects,
    ]
  ] + [
    panel.thirdRow(p)
    for p in [
      panels.vehicles.disconnectDurationP50,
      panels.vehicles.disconnectDurationP99,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'vehicle-controller (promql)',
  uid='vehicle-domain_vehicle-controller_promql',
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
    query='vehicle-controller',
    current='vehicle-controller',
    hide='variable',
  )
)

.addRows([
  k8s.rows.service,
  k8s.rows.kafka,
  panel.collapseRow(k8s.rows.postgres),
  rows.georegion,
  rows.state,
  rows.vehicles,
])
