local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local panel = import '../../helper/panel.libsonnet';
local gcp = import '../../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;
local k8s = import '../k8s.libsonnet';

local filters = {
  manufacturer: gcp.likeFilter(l('manufacturer'), '$manufacturer'),
  firmware: [] // gcp.likeFilter(l('firmware'), '$firmware'), // deactivating firmware until used in prod
};

local targets = {
  georegion: {
    switches: gcp.counter(
      alias='switches',
      metric=m('georegion-switch'),
    ),
    global: gcp.counter(
      alias='global',
      metric=m('georegion-global'),
    ),
    country: gcp.counter(
      alias='country',
      metric=m('georegion-country'),
    ),
    city: gcp.counter(
      alias='city',
      metric=m('georegion-city'),
    ),
    geofence: gcp.counter(
      alias='geofence',
      metric=m('georegion-geofence'),
    ),
  },
  state: {
    processingTime: gcp.timers(
      metric=m('kafka-consume-duration'),
      filters=gcp.equalsFilter(l('kafka_source_topic'), 'vehicle-state'),
    ),
    flushes: gcp.timers(m('flush-duration')),
    flushAmount: gcp.gauges(m('vehicle-repository-flush-amount')),
    changeTime: gcp.timers(
      metric=m('state-changed-latency'),
      groupBys=[l('state_name')],
    ),
    changes: gcp.counter(
      metric=m('state-changed'),
      groupBys=[l('state_name')],
    ),
    changeErrors: gcp.counter(
      metric=m('state-changed-error'),
      groupBys=[l('state_name')],
    ),
  }
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
  }
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
  ])
