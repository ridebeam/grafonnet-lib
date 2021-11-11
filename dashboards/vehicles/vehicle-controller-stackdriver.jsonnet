local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local k8s_helper = import '../k8s.libsonnet';
local gcp = import '../../helper/gcp.libsonnet';

local k8s = k8s_helper.init();
local helpers = gcp.init();
local target = helpers.target;
local panel = helpers.panel;
local m = target.customMetric;
local l = target.label;

local filters = {
  manufacturer: target.likeFilter(l('manufacturer'), '$manufacturer'),
};

local targets = {
  georegion: {
    switches: target.counter(
      alias='switches',
      metric=m('georegion-switch'),
    ),
    global: target.counter(
      alias='global',
      metric=m('georegion-global'),
    ),
    country: target.counter(
      alias='country',
      metric=m('georegion-country'),
    ),
    city: target.counter(
      alias='city',
      metric=m('georegion-city'),
    ),
    geofence: target.counter(
      alias='geofence',
      metric=m('georegion-geofence'),
    ),
  },
  state: {
    processingTime: target.timers(
      metric=m('kafka-consume-duration'),
      filters=target.equalsFilter(l('kafka_source_topic'), 'vehicle-state'),
    ),
    flushes: target.timers(m('flush-duration')),
    flushAmount: target.gauges(m('vehicle-repository-flush-amount')),
    changeTime: target.timers(
      metric=m('state-changed-latency'),
      groupBys=[l('state_name')],
    ),
    changes: target.counter(
      metric=m('state-changed'),
      groupBys=[l('state_name')],
    ),
    changeErrors: target.counter(
      metric=m('state-changed-error'),
      groupBys=[l('state_name')],
    ),
  },
  vehicles: {
    disconnects: target.counter(
      metric=m('iot-disconnected'),
      groupBys=[l('city_id')],
    ),
    reconnects: target.counter(
      metric=m('iot-disconnected-dead-connection'),
      groupBys=[l('city_id')],
    ),
    disconnectDuration: target.timers(
      metric=m('iot-disconnected-duration'),
      groupBys=[l('city_id')],
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
      targets.state.processingTime.avg,
      targets.state.processingTime.p50,
      targets.state.processingTime.p99,
    ]),
    flushes: panel.timeLinear('Full Flush duration').addTargets([
      targets.state.flushes.p50,
      targets.state.flushes.p99,
    ]),
    flushAmount: panel.new('Full Flush Entries').addTargets([
      targets.state.flushAmount.p50,
      targets.state.flushAmount.p99,
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
    disconnectDurationAvg: panel.timeLinear('Time Disconnected avg').addTargets([
      targets.vehicles.disconnectDuration.avg,
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
      panels.vehicles.disconnectDurationAvg,
      panels.vehicles.disconnectDurationP50,
      panels.vehicles.disconnectDurationP99,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'vehicle-controller',
  uid='vehicle-domain_vehicle-controller',
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
