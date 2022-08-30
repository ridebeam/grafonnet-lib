local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

local targets = {
  addVehicles: {
    attempt: target.counter(
      metric='register-vehicles-attempt',
    ),
    success: target.counter(
      metric='register-vehicles-success',
    ),
  },
  addRide: {
    attempt: target.counter(
      metric='unet-add-ride-attempt',
    ),
    success: target.counter(
      metric='unet-add-ride-success',
    ),
    timing: target.timers(
      metric='unet-add-ride-timing',
    ),
  },
  addLocation: {
    attempt: target.counter(
      metric='unet-add-location-attempt',
    ),
    success: target.counter(
      metric='unet-add-location-success',
    ),
    timing: target.timers(
      metric='unet-add-location-timing',
    ),
  },
  addStatus: {
    attempt: target.counter(
      metric='unet-vehicle-status-update-attempt',
    ),
    success: target.counter(
      metric='unet-vehicle-status-update-success',
    ),
    timing: target.timers(
      metric='unet-vehicle-status-update-timing',
    ),
  },
  errors: {
    getUserInfo: target.counter(
      metric='unet-get-user-info-error',
    ),
    addRideApiError: target.counter(
      metric='unet-add-ride-error',
    ),
    addRideDbError: target.counter(
      metric='unet-failed-to-save-ride',
    ),
    addStatusError: target.counter(
      metric='unet-vehicle-status-update-error'
    ),
  },
  unetApi: {
    count: target.counter(
      metric='unet-api-request',
      groupBys=['unet_api_path'],
    ),
    latency: target.timers(
      metric='unet-api-request-latency',
      groupBys=['unet_api_path'],
    ),
  },
};

local panels = {
  service: {
    addVehicleCounts: panel.counter('Add Vehicle Counts').addTargets([
      targets.addVehicles.attempt,
      targets.addVehicles.success,
    ]),
    addRideCounts: panel.counter('Add Ride Counts').addTargets([
      targets.addRide.attempt,
      targets.addRide.success,
    ]),
    addRideLatency: panel.timeLinear('Add Ride Latency').addTargets([
      targets.addRide.timing.p99,
      targets.addRide.timing.p95,
      targets.addRide.timing.p50,
    ]),
    addLocationCounts: panel.counter('Add Location Counts').addTargets([
      targets.addLocation.attempt,
      targets.addLocation.success,
    ]),
    addLocationLatency: panel.timeLinear('Add Location Latency').addTargets([
      targets.addLocation.timing.p99,
      targets.addLocation.timing.p95,
      targets.addLocation.timing.p50,
    ]),
    addStatusCounts: panel.counter('Add Status Counts').addTargets([
      targets.addStatus.attempt,
      targets.addStatus.success,
    ]),
    addStatusLatency: panel.timeLinear('Add Status Latency').addTargets([
      targets.addStatus.timing.p99,
      targets.addStatus.timing.p95,
      targets.addStatus.timing.p50,
    ]),
  },
  errors: {
    general: panel.counter('Errors').addTargets([
      targets.errors.addRideApiError,
      targets.errors.addRideDbError,
      targets.errors.getUserInfo,
      targets.errors.addStatusError,
    ]),
  },
  unetApi: {
    requestCount: panel.counter('API request').addTargets([
      targets.unetApi.count,
    ]),
    latency: panel.timeLinear('API latency').addTargets([
      targets.unetApi.latency.p99,
      targets.unetApi.latency.p95,
      targets.unetApi.latency.p50,
    ]),
  },
};

local rows = {
  service: row.new('Unet Service').addPanels([
    panel.halfRow(p)
    for p in [
      panels.service.addVehicleCounts,
      panels.service.addRideCounts,
      panels.service.addRideLatency,
      panels.service.addLocationCounts,
      panels.service.addLocationLatency,
      panels.service.addStatusCounts,
      panels.service.addStatusLatency,
    ]
  ]),
  unetApi: row.new('Unet API').addPanels([
    panel.halfRow(p)
    for p in [
      panels.unetApi.requestCount,
      panels.unetApi.latency,
    ]
  ]),
  errors: row.new('Errors').addPanels([
    panel.halfRow(p)
    for p in [
      panels.errors.general,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Unet Overview',
  uid='unet-overview',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)
.addTemplate(
  template.custom(
    name='env',
    query='staging,production',
    current='production',
  )
)
.addTemplate(
  template.custom(
    name='service',
    query='unet',
    current='unet',
    hide='variable',
  )
)
.addRows([
  k8s.rows.service,
  rows.service,
  rows.unetApi,
  rows.errors,
  panel.collapseRow(k8s.rows.grpc),
  panel.collapseRow(k8s.rows.postgres),
  panel.collapseRow(k8s.rows.kafka),
])
