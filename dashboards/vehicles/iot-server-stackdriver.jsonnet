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
  firmware: [],  // target.likeFilter(l('firmware'), '$firmware'), // deactivating firmware until used in prod
};

local targets = {
  connections: {
    combined: target.gauge(
      alias='combined',
      metric=m('server-devices-connected'),
      filters=filters.manufacturer,
      aligner=target.gaugeReducers.sum.aligner,
      reducer=target.gaugeReducers.sum.reducer,
    ),
    each: target.gauge(
      metric=m('server-devices-connected'),
      filters=filters.manufacturer,
      groupBys=[l('manufacturer')],
      aligner=target.gaugeReducers.sum.aligner,
      reducer=target.gaugeReducers.sum.reducer,
    ),
    perInstance: target.gauge(
      metric=m('server-devices-connected'),
      filters=filters.manufacturer,
      groupBys=['resource.label.pod_name'],
      aligner=target.gaugeReducers.sum.aligner,
      reducer=target.gaugeReducers.sum.reducer,
    ),
    new: target.counter(
      alias='incoming',
      metric=m('server-incoming'),
      filters=filters.manufacturer,
      groupBys=[l('manufacturer')],
    ),
    failed: target.counter(
      alias='failed to connect',
      metric=m('server-incoming-error'),
      filters=filters.manufacturer,
      groupBys=[l('manufacturer')],
    ),
    prodDisconnects: cloudwatch.target(
      region='default',
      namespace='BeamAPI',
      metric='beam_api_Production_Vehicles_NinebotOmni_VehicleDisconnected',
      statistic='Sum',
    ),
  },
  commands: {
    received: target.counter(
      metric=m('adapter-incoming'),
      filters=target.combineFilters(
        filters.firmware,
        filters.manufacturer,
      ),
      groupBys=[l('cmd')],
    ),
    receivedFW: target.counter(
      metric=m('adapter-incoming'),
      filters=filters.manufacturer,
      groupBys=[l('firmware')],
    ),
    send: target.counter(
      metric=m('device-outgoing'),
      filters=target.combineFilters(
        filters.firmware,
        filters.manufacturer,
      ),
      groupBys=[l('cmd_outgoing')],
    ),
    rerouted: target.counter(
      metric=m('gateway-incoming-rerouted'),
    ),
    traffic: {
      read: target.counter(
        alias='read',
        metric=m('device-incoming-bytes'),
      ),
      write: target.counter(
        alias='write',
        metric=m('device-outgoing-bytes'),
      ),
      skipped: target.counter(
        alias='skipped',
        metric=m('device-incoming-bytes-skipped'),
      ),
    },
  },
};

local panels = {
  connections: {
    connected: panel.new('Connected Devices').addTargets([
      targets.connections.combined,
      targets.connections.each,
    ]),
    newConnections: panel.counter('Connection Requests (including health checks and errors)').addTargets([
      targets.connections.new,
      targets.connections.failed,
    ]),
    perInstance: panel.new('Connected Devices per Instance').addTargets([
      targets.connections.perInstance,
    ]),
    prodDisconnects: graphPanel.new('[Prod] Disconnect Events', datasource='CloudWatch', legend_show=false).addTargets([
      targets.connections.prodDisconnects,
    ]),
  },
  commands: {
    received: panel.counter('Received').addTargets([
      targets.commands.received,
    ]),
    receivedFW: panel.counter('Received per Firmware').addTargets([
      targets.commands.receivedFW,
    ]),
    send: panel.counter('Send').addTargets([
      targets.commands.send,
    ]),
    rerouted: panel.counter('Rerouted', legend_show=false).addTargets([
      targets.commands.rerouted,
    ]),
    traffic: panel.counter('TCP Traffic', 'Bps').addTargets([
      targets.commands.traffic.read,
      targets.commands.traffic.write,
      targets.commands.traffic.skipped,
    ]),
  },
};

local rows = {
  connections: row.new('Connections').addPanels([
    panel.halfRow(p)
    for p in [
      panels.connections.connected,
      panels.connections.newConnections,
      panels.connections.perInstance,
      panels.connections.prodDisconnects,
    ]
  ]),
  commands: row.new('Commands').addPanels([
    panel.halfRow(p)
    for p in [
      panel.showTable(panels.commands.received, avg=true, current=true),
      panel.showTable(panels.commands.receivedFW, avg=true, current=true),
      panel.showTable(panels.commands.send, avg=true, current=true),
      panels.commands.rerouted,
      panel.showTable(panels.commands.traffic, avg=true, current=true),
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'iot-server',
  uid='vehicle-domain_iot-server',
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
    query='iot-server',
    current='iot-server',
    hide='variable',
  )
)

.addTemplate(
  template.custom(
    name='manufacturer',
    query='omni,okai',
    allValues='.*',
    current='All',
    includeAll=true,
  )
)

//  .addTemplate(
//    template.custom(
//      name='firmware',
//      query='1414,1411,1394,unknown',
//      allValues='.*',
//      current='All',
//      includeAll=true,
//    )
//  )

.addRows([
  k8s.rows.service,
  panel.collapseRow(k8s.rows.http),
  k8s.rows.kafka,
  panel.collapseRow(k8s.rows.postgres),
  rows.connections,
  rows.commands,
])
