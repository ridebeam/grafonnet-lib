local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  kafka: {
    consumed: target.counter(
      metric='handle_kafka_message',
      groupBys=['topic'],
    ),
    lag: target.timers(
      metric='kafka-consume-lag',
      groupBys=['kafka_source_topic'],
    ),
  },
  vehicles: {
    events: target.counter(
      metric='handle.vehicle.event.count',
      groupBys=['property'],
    ),
    eventHandlingDuration: target.timers(
      metric='handle.vehicle.event.duration',
      groupBys=['property'],
    ),
    skippedEvents: target.counter(
      metric='handle.skipped.vehicle.event.count',
      groupBys=['reason'],
    ),
    eventHandlingTotal: target.timers(
      metric='vehicle-event-latency',
    ),
  },
};

local panels = {
  kafka: {
    consume: panel.counter('Consumed').addTarget(targets.kafka.consumed),
    lagP99: panel.timeLog2('Consumer Lag P99').addTarget(targets.kafka.lag.p99),
    lagP50: panel.timeLog2('Consumer Lag P50').addTarget(targets.kafka.lag.p50),
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
  uid='prom_api_messaging',
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
