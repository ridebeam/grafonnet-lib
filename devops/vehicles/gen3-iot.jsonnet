// TODO: rename this file to vehicle deployment monitoring
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
  manufacture: target.likeFilter('manufacture', '$manufacturer'),
  firmware: target.likeFilter('firmware', '$firmware'),
  model: target.likeFilter('vehicle_model', '$vehicle_model'),
  city: target.notEqualFilter('city_id', '223'), // ignore data from China factory
  vehicleStatus: target.likeFilter('vehicle_status', '$vehicle_status')
};

local commonFilters = target.combineFilterArray([filters.model, filters.manufacturer, filters.firmware, filters.city]);
local commonAPIFilters = target.combineFilterArray([filters.model, filters.manufacture, filters.firmware]);
local beamAPIFilter = target.likeFilter('service', 'api|messaging');

local targets = {
  systemError: {
    // lock unlock errors
    ecuLockUnlockError: target.counter(
      metric='action-error',
      filters=target.combineFilters(target.equalsFilter('state_name', 'ecuLock'), commonFilters),
    ),
    batteryHatchUnlockError: target.counter(
      metric='action-error',
      filters=target.combineFilters(target.equalsFilter('state_name', 'batteryLock'), commonFilters),
    ),
    helmetUnlockError: target.counter(
      metric='action-error',
      filters=target.combineFilters(target.equalsFilter('state_name', 'helmetLock'), commonFilters),
    ),
    // invalid data
    invalidLocation: target.counter(
      metric='invalid-location',
      filters=commonFilters,
    ),
    invalidBatteryPercentage: target.counter(
      metric='invalid-battery-percentage',
      filters=commonFilters,
    ),
    invalidWheelSpeed: target.counter(
      metric='invalid-wheel-speed',
      filters=commonFilters,
    ),
    invalidMileage: target.counter(
      metric='invalid-mileage-value',
      filters=commonFilters,
    ),
    // error codes
    errorReport: target.counter(
      metric='error-report',
      filters=commonFilters,
    ),
    clearError: target.counter(
      metric='clear-error',
      filters=commonFilters,
    ),
    // alarms
    alarmReport: target.counter(
      metric='alarm-report',
      filters=commonFilters,
    ),
    // disconnection
    disconnection: target.counter(
      metric='disconnection',
      filters=commonFilters,
    ),
    // firmware errors
    flashFirmwareError: target.counter(
      metric='flash-firmware-error',
      filters=commonFilters,
    ),
    // message parsing errors
    messageError: target.counter(
      metric='adapter-incoming-error',
      filters=commonFilters,
    ),
  },
  systemDelay: {
    ecuLockUnlockDelay: target.timers(
      metric='unlock-via-power-control-duration',
      filters=commonFilters,
    ),
    ecuLockUnlockLatency: target.timers(
      metric='ecu-unlock-timing',
      filters=commonFilters,
    ),
    batteryLockDelay: target.timers(
      metric='unlock-battery-hatch-timing',
      filters=commonFilters,
    ),
    helmetLockDelay: target.timers(
      metric='helmet-lock-timing',
      filters=commonFilters,
    ),
  },
  volumeTraffic: {
    countAll: target.gauges(
      'vehicle-connected-count',
      filters=target.combineFilters(filters.model, filters.manufacturer),
      withServiceFilters=false,
    ),
    received: target.counter(
      metric='adapter-incoming',
      filters=commonFilters,
      groupBys=['cmd'],
    ),
    send: target.counter(
      metric='device-outgoing',
      filters=commonFilters,
      groupBys=['cmd_outgoing'],
    ),
  },
  businessVolume: {
    startTrip: target.counter(
      metric='start-trip',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, commonAPIFilters)
    ),
    startTripHelmetUnlocked: target.counter(
      metric='trip-helmet-unlock',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, commonAPIFilters)
    ),
    riderEndTripLocked: target.counter(
      metric='rider-end-trip-lock-success',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, commonAPIFilters)
    ),
    adminEndTripLocked: target.counter(
      metric='admin-end-trip-lock-success',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, commonAPIFilters)
    ),
    riderTripReview1: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 1)), commonAPIFilters)
    ),
    riderTripReview2: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 2)), commonAPIFilters)
    ),
    riderTripReview3: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 3)), commonAPIFilters)
    ),
    riderTripReview4: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 4)), commonAPIFilters)
    ),
    riderTripReview5: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 5)), commonAPIFilters)
    ),
  },
  businessLatency: {
    vehicleUnlockLatency: target.timers(
      withServiceFilters=false,
      metric='start-trip-timing',
      filters=target.combineFilters(beamAPIFilter, commonAPIFilters)
    ),
    batteryHatchUnlockLatency: target.timers(
      withServiceFilters=false,
      metric='battery-hatch-open-latency',
      filters=target.combineFilters(beamAPIFilter, commonAPIFilters)
    ),
    helmetUnlockLatency: target.timers(
      withServiceFilters=false,
      metric='helmet-unlock-latency',
      filters=target.combineFilters(beamAPIFilter, commonAPIFilters)
    ),
  },
};

local panels = {
  systemError: {
    lockUnlockError: panel.counter('Lock Unlock Error').addTargets([
      targets.systemError.ecuLockUnlockError,
      targets.systemError.batteryHatchUnlockError,
      targets.systemError.helmetUnlockError,
    ]),
    invalidData: panel.counter('Invalid Data').addTargets([
      targets.systemError.invalidLocation,
      targets.systemError.invalidWheelSpeed,
      targets.systemError.invalidBatteryPercentage,
      targets.systemError.invalidMileage,
    ]),
    errorCodes: panel.counter('Error Codes').addTargets([
      targets.systemError.errorReport,
      targets.systemError.clearError,
    ]),
    alarm: panel.counter('Alarms').addTargets([
      targets.systemError.alarmReport,
    ]),
    disconnection: panel.counter('Disconnection').addTargets([
      targets.systemError.disconnection,
    ]),
    firmware: panel.counter('Firmware Errors').addTargets([
      targets.systemError.flashFirmwareError,
    ]),
    messageError: panel.counter('Message Errors').addTargets([
      targets.systemError.messageError,
    ]),
  },
  systemDelay: {
    ecuLockUnlockDelay: panel.timeLinear('ECU Lock Delay').addTargets([
      targets.systemDelay.ecuLockUnlockDelay.p99,
      targets.systemDelay.ecuLockUnlockDelay.p95,
      targets.systemDelay.ecuLockUnlockDelay.p50,
    ]),
    ecuLockUnlockLatency: panel.timeLinear('ECU Lock / Unlock Latency').addTargets([
      targets.systemDelay.ecuLockUnlockLatency.p99,
      targets.systemDelay.ecuLockUnlockLatency.p95,
      targets.systemDelay.ecuLockUnlockLatency.p50,
    ]),
    batteryLockDelay: panel.timeLinear('Battery Lock Delay').addTargets([
      targets.systemDelay.batteryLockDelay.p99,
      targets.systemDelay.batteryLockDelay.p95,
      targets.systemDelay.batteryLockDelay.p50,
    ]),
    helmetLockDelay: panel.timeLinear('Helmet Lock Delay').addTargets([
      targets.systemDelay.helmetLockDelay.p99,
      targets.systemDelay.helmetLockDelay.p95,
      targets.systemDelay.helmetLockDelay.p50,
    ]),
  },
  volumeTraffic: {
    vehicleCount: panel.counter(title='Vehicle Count', format='none').addTargets([
      targets.volumeTraffic.countAll.max.withAlias('total'),
    ]),
    messagesReceived: panel.counter('Messages Received').addTargets([
      targets.volumeTraffic.received,
    ]),
    messagesSent: panel.counter('Messages Sent').addTargets([
      targets.volumeTraffic.send,
    ]),
  },
  businessVolume: {
    startTrip: panel.counter('start trip unlock success count').addTargets([
      targets.businessVolume.startTrip,
    ]),
    startTripHelmetUnlocked: panel.counter('start trip helmet unlocked count').addTargets([
      targets.businessVolume.startTripHelmetUnlocked,
    ]),
    riderEndTripLocked: panel.counter('end trip locked by rider').addTargets([
      targets.businessVolume.riderEndTripLocked,
    ]),
    adminEndTripLocked: panel.counter('end trip locked by admin or system').addTargets([
      targets.businessVolume.adminEndTripLocked,
    ]),
    tripReview: panel.counter('trip review rating').addTargets([
      targets.businessVolume.riderTripReview1,
      targets.businessVolume.riderTripReview2,
      targets.businessVolume.riderTripReview3,
      targets.businessVolume.riderTripReview4,
      targets.businessVolume.riderTripReview5,
    ]),
  },
  businessLatency: {
    vehicleUnlockLatency: panel.timeLinear('Vehicle Unlock Latency').addTargets([
      targets.businessLatency.vehicleUnlockLatency.p99,
      targets.businessLatency.vehicleUnlockLatency.p95,
      targets.businessLatency.vehicleUnlockLatency.p50,
    ]),
    batteryHatchUnlockLatency: panel.timeLinear('Battery Hatch Unlock Latency').addTargets([
      targets.businessLatency.batteryHatchUnlockLatency.p99,
      targets.businessLatency.batteryHatchUnlockLatency.p95,
      targets.businessLatency.batteryHatchUnlockLatency.p50,
    ]),
    helmetUnlockLatency: panel.timeLinear('Helmet Unlock Latency').addTargets([
      targets.businessLatency.helmetUnlockLatency.p99,
      targets.businessLatency.helmetUnlockLatency.p95,
      targets.businessLatency.helmetUnlockLatency.p50,
    ]),
  },
};

local rows = {
  systemError: row.new('System Errors').addPanels([
    panel.halfRow(p)
    for p in [
      panels.systemError.lockUnlockError,
      panels.systemError.invalidData,
      panels.systemError.errorCodes,
      panels.systemError.alarm,
      panels.systemError.disconnection,
      panels.systemError.firmware,
      panels.systemError.messageError,
    ]
  ]),
  systemDelay: row.new('System Delays').addPanels([
    panel.halfRow(p)
    for p in [
      panels.systemDelay.ecuLockUnlockDelay,
      panels.systemDelay.ecuLockUnlockLatency,
      panels.systemDelay.batteryLockDelay,
      panels.systemDelay.helmetLockDelay,
    ]
  ]),
  volumeTraffic: row.new('Volume Traffic').addPanels([
    panel.halfRow(p)
    for p in [
      panels.volumeTraffic.vehicleCount,
      panels.volumeTraffic.messagesReceived,
      panels.volumeTraffic.messagesSent,
    ]
  ]),
  businessVolume: row.new('Business Volume').addPanels([
    panel.halfRow(p)
    for p in [
      panels.businessVolume.startTrip,
      panels.businessVolume.startTripHelmetUnlocked,
      panels.businessVolume.riderEndTripLocked,
      panels.businessVolume.adminEndTripLocked,
      panels.businessVolume.tripReview,
    ]
  ]),
  businessLatency: row.new('Business Latency').addPanels([
    panel.halfRow(p)
    for p in [
      panels.businessLatency.vehicleUnlockLatency,
      panels.businessLatency.batteryHatchUnlockLatency,
      panels.businessLatency.helmetUnlockLatency,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'gen3-iot',
  uid='vehicle-domain_gen3-iot_promql',
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
    query='omni,okai,omnigen3,omniat',
    allValues='.*',
    current='All',
    includeAll=true,
  )
)

.addTemplate(
  template.new(
    name='firmware',
    datasource=null,
    query='label_values(adapter_incoming{vehicle_status=~"rider|standy"}, firmware)',
    allValues='.*',
    current='All',
    includeAll=true,
    refresh=1,
    sort=1,
  )
)

.addTemplate(
  template.new(
    name='vehicle_model',
    datasource=null,
    query='label_values(adapter_incoming{vehicle_status=~"rider|standy"}, vehicle_model)',
    allValues='.*',
    current='All',
    includeAll=true,
  )
)

.addTemplate(
  template.custom(
    name='vehicle_status',
    query='rider,standy,operations,manual',
    allValues='.*',
    current='All',
    includeAll=true,
  )
)

.addRows([
  rows.systemError,
  rows.systemDelay,
  rows.volumeTraffic,
  rows.businessVolume,
  rows.businessLatency,
])
