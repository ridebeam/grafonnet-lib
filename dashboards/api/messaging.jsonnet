local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local panel = import '../../helper/panel.libsonnet';
local target = import '../../helper/target.libsonnet';
local gcp = import '../../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;

local targets = {
  kafka: {
    scooterMessages: gcp.counter(
      metric=m('scooter-messages'),
    ),
    vehicleEvent: gcp.counter(
      metric=m('vehicle-event'),
    ),
    lag: gcp.timers(
      metric=m('kafka-consume-lag'),
      groupBys=[l('kafka_source_topic')],
    ),
  },
  vehicles: {
    events: gcp.counter(
      metric=m('handle.vehicle.event.count'),
      groupBys=[l('property')],
    ),
    eventHandlingDuration: gcp.timers(
      metric=m('handle.vehicle.event.duration'),
      groupBys=[l('property')],
    ),
  },
};

local panels = {
  kafka: {
    consume: panel.counter('Consumed').addTargets([
      target.alias(targets.kafka.scooterMessages, "scooter-messages"),
      target.alias(targets.kafka.vehicleEvent, "vehicle-event")
    ]),
    lagP99: panel.timeLog2('Consumer Lag P99').addTarget(targets.kafka.lag.p99),
    lagP50: panel.timeLog2('Consumer Lag P50').addTarget(targets.kafka.lag.p50),
    lagAvg: panel.timeLog2('Consumer Lag AVG').addTarget(targets.kafka.lag.avg),
  },
  vehicles: {
    events: panel.counter('Events').addTarget(targets.vehicles.events),
    eventHandlingDuration: panel.timeLog2('Event Handling Duration').addTarget(targets.vehicles.eventHandlingDuration.p99),
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
      query='api,messaging', // 'api' is only a valid choice for dev and staging envs
      current='messaging',
    )
  )

  .addRows([
    rows.kafka,
    rows.vehicles,
  ])
