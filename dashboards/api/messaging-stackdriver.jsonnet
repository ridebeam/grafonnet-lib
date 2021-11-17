local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local k8s_helper = import '../k8s-stackdriver.libsonnet';
local gcp = import '../../helper/gcp.libsonnet';

local k8s = k8s_helper.init();
local helpers = gcp.init();
local target = helpers.target;
local panel = helpers.panel;
local m = target.customMetric;
local l = target.label;

local targets = {
  kafka: {
    scooterMessages: target.counter(
      metric=m('scooter-messages'),
    ),
    vehicleEvent: target.counter(
      metric=m('vehicle-event'),
    ),
    lag: target.timers(
      metric=m('kafka-consume-lag'),
      groupBys=[l('kafka_source_topic')],
    ),
  },
  vehicles: {
    events: target.counter(
      metric=m('handle.vehicle.event.count'),
      groupBys=[l('property')],
    ),
    eventHandlingDuration: target.timers(
      metric=m('handle.vehicle.event.duration'),
      groupBys=[l('property')],
    ),
    skippedEvents: target.counter(
      metric=m('handle.skipped.vehicle.event.count'),
      groupBys=[l('reason')],
    ),
    eventHandlingTotal: target.timers(
      metric=m('vehicle-event-latency'),
    ),
  },
};

local panels = {
  kafka: {
    consume: panel.counter('Consumed').addTargets([
      targets.kafka.scooterMessages.withAlias('scooter-messages'),
      targets.kafka.vehicleEvent.withAlias('vehicle-event'),
    ]),
    lagP99: panel.timeLog2('Consumer Lag P99').addTarget(targets.kafka.lag.p99),
    lagP50: panel.timeLog2('Consumer Lag P50').addTarget(targets.kafka.lag.p50),
    lagAvg: panel.timeLog2('Consumer Lag AVG').addTarget(targets.kafka.lag.avg),
  },
  vehicles: {
    events: panel.counter('Events').addTarget(targets.vehicles.events),
    eventHandlingDuration: panel.timeLog2('Event Handling Duration').addTarget(targets.vehicles.eventHandlingDuration.p99),
    skippedEvents: panel.counter('Skipped Events').addTarget(targets.vehicles.skippedEvents),
    eventHandlingTotal: panel.timeLog2('Event Handling E2E', format='ms').addTarget(targets.vehicles.eventHandlingTotal.p95),
  },
};

local rows = {
  kafka: row.new('Kafka').addPanels([
    panel.halfRow(p)
    for p in [
      panels.kafka.consume,
      panels.kafka.lagP99,
      panels.kafka.lagP50,
      panels.kafka.lagAvg,
    ]
  ]),
  vehicles: row.new('Vehicles').addPanels([
    panel.halfRow(p)
    for p in [
      panels.vehicles.events,
      panels.vehicles.eventHandlingDuration,
      panels.vehicles.skippedEvents,
      panels.vehicles.eventHandlingTotal,
    ]
  ]),
};

grafana.dashboard.new(
  'messaging',
  uid='api_messaging',
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
    query='api,messaging',  // 'api' is only a valid choice for dev and staging envs
    current='messaging',
  )
)

.addRows([
  rows.kafka,
  rows.vehicles,
])
