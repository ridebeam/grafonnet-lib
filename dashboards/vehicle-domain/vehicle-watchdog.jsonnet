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
  country: target.likeFilter('country', '$country'),
};

local targets = {
  session_duration: target.timers(
    metric='vehicle-connection-duration',
    interval='24h',
    filters=filters.country,
    groupBys=['country', 'operator'],
  ),
  call_duration: target.timers(
    metric='twilio-get-session-duration',
  ),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'vehicle-watchdog',
  uid='vehicle-domain_vehicle-watchdog',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addTemplate(
  template.custom(
    name='env',
    query='production',
    current='production',
    hide='variable',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='vehicle-watchdog',
    current='vehicle-watchdog',
    hide='variable',
  )
)

.addTemplate(
  template.new(
    name='country',
    datasource=null,
    query='label_values(vehicle_connection_established, country)',
    allValues='.*',
    current='All',
    includeAll=true,
    refresh=1,
    sort=1,
  )
)

.addRows([
  row.new('connections').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('per country').addTargets([
        target.counter(
          metric='vehicle-connection-established',
          intervalFactor=10,
          filters=filters.country,
          groupBys=['country'],
        ),
      ]),
      panel.counter('per operator').addTargets([
        target.counter(
          metric='vehicle-connection-established',
          intervalFactor=10,
          filters=filters.country,
          groupBys=['country', 'operator'],
        ),
      ]),
    ]
  ]),

  row.new('sessions').addPanels([
    panel.thirdRow(p)
    for p in [
      panel.timeLinear('duration P95 (daily rate)').addTargets([
        targets.session_duration.p95,
      ]),
      panel.timeLinear('duration P50 (daily rate)').addTargets([
        targets.session_duration.p50,
      ]),
      panel.timeLinear('duration P5 (daily rate)').addTargets([
        targets.session_duration.p05,
      ]),
    ]
  ] + [
    panel.halfRow(p)
    for p in [
      panel.counter('data packets downloaded (daily rate)').addTargets([
        target.counter(
          metric='vehicle-connection-packets-downloaded',
          interval='24h',
          filters=filters.country,
          groupBys=['country', 'operator'],
        ),
      ]),
      panel.counter('sessions without data').addTargets([
        target.counter(
          metric='vehicle-connection-without-data',
          intervalFactor=10,
          filters=filters.country,
          groupBys=['country', 'operator'],
        ),
      ]),
      panel.counter('data packets uploaded (daily rate)').addTargets([
        target.counter(
          metric='vehicle-connection-packets-uploaded',
          interval='24h',
          filters=filters.country,
          groupBys=['country', 'operator'],
        ),
      ]),
    ]
  ]),

  panel.collapseRow(row.new('debug').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLog2('GET twillio SID and Session').addTargets([
        targets.call_duration.p99,
        targets.call_duration.p95,
        targets.call_duration.p50,
      ]),
      panel.counter('GET sid error').addTargets([
        target.counter(
          metric='twilio-get-sid-error',
        ),
      ]),
      panel.counter('GET session error').addTargets([
        target.counter(
          metric='twilio-get-session-error',
        ),
      ]),
      panel.counter('vehicle missing ICCID').addTargets([
        target.counter(
          metric='vehicle-data-incomplete',
        ),
      ]),
    ]
  ])),
])
