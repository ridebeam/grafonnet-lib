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
  disconnected_duration: target.timers(
    metric='vehicle-connection-reconnect-duration',
    interval='24h',
    filters=filters.country,
    groupBys=['country', 'operator'],
  ),
  call_duration: target.timers(
    metric='twilio-get-session-duration',
  ),
  disconnected_sessions_amount: target.timers(
    metric='twilio-get-session-amount',
  ),
};

local panels = {
  sessions_no_data: panel.counter(
    'sessions without data *',
    description='possible data completetion issue with data sessions not containing data on retrieval',
  ).addTargets([
    target.counter(
      metric='vehicle-connection-without-data',
      intervalFactor=10,
      filters=filters.country,
      groupBys=['country', 'operator'],
    ),
  ]),
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
  row.new('Connection Issue Debugging').addPanels([
    panel.thirdRow(p)
    for p in [
      panel.counter('new TCP connections per country').addTargets([
        target.counter(
          metric='vehicle-connection-established',
          intervalFactor=10,
          filters=filters.country,
          groupBys=['country'],
        ),
      ]),
      panel.counter('new TCP connections per operator').addTargets([
        target.counter(
          metric='vehicle-connection-established',
          intervalFactor=10,
          filters=filters.country,
          groupBys=['country', 'operator'],
        ),
      ]),
      panels.sessions_no_data,
    ]
  ]),

  panel.collapseRow(row.new('Twilio - New Connections').addPanels([
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
  ])),

  panel.collapseRow(row.new('Twilio - Data Sessions (possible data issues, see code comments)').addPanels([
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
      panel.timeLinear('time between data sessions P95 (daily rate)').addTargets([
        targets.disconnected_duration.p95,
      ]),
      panel.timeLinear('time between data sessions P50 (daily rate)').addTargets([
        targets.disconnected_duration.p50,
      ]),
      panel.timeLinear('time between data sessions P5 (daily rate)').addTargets([
        targets.disconnected_duration.p05,
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
      panels.sessions_no_data,
      panel.new(
        'vehicles without sessions',
        description='We keep track of disconnected vehicles that had no data sessions in a while. During restarts this might zero out, and gets repopulated after a few mins',
        legend_show=false,
      ).addTargets([
        target.gauges(
          metric='vehicle-connection-no-sessions',
        ).sum,
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
  ])),

  panel.collapseRow(row.new('Twilio - Debug').addPanels([
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
      panel.timeLinear('sessions per disconnected vehicle', format='short').addTargets([
        targets.disconnected_sessions_amount.p99,
        targets.disconnected_sessions_amount.p95,
        targets.disconnected_sessions_amount.p50,
      ]),
    ]
  ])),
  panel.collapseRow(row.new('Vehicle Helmet Lock Type')).addPanels([
    panel.counter('number of helmet by city').addTargets([
      target.gauges(
        metric='vehicle_helmet_lock',
        groupBys=['city_id', 'helmet_lock_type'],
      ).avg,
    ]),
  ]),
])
