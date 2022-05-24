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
  firmware: target.likeFilter('firmware', '$firmware'),
};

local beamAPIFilter = target.likeFilter('service', 'api|messaging');

local targets = {
  systemError: {
    ecuLockUnlockError: target.counter(
      metric='action-error',
      filters=target.combineFilters(target.equalsFilter('state', 'ecuLock'), target.combineFilters(filters.manufacturer, filters.firmware)),
    ),
    batteryHatchUnlockError:  target.counter(
      metric='action-error',
      filters=target.combineFilters(target.equalsFilter('state', 'batteryLock'), target.combineFilters(filters.manufacturer, filters.firmware)),
    ),
    helmetUnlockError:  target.counter(
      metric='action-error',
      filters=target.combineFilters(target.equalsFilter('state', 'helmetLock'), target.combineFilters(filters.manufacturer, filters.firmware)),
    ),
    invalidLocation:  target.counter(
      metric='invalid-location',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    invalidBatteryPercentage:  target.counter(
      metric='invalid-battery-percentage',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    invalidWheelSpeed:  target.counter(
      metric='invalid-wheel-speed',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    errorReport:  target.counter(
      metric='error-report',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    clearError:  target.counter(
      metric='clear-error',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    alarmReport:  target.counter(
      metric='alarm-report',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    disconnection: target.counter(
      metric='disconnection',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    flashFirmwareError:  target.counter(
      metric='flash-firmware-error',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
    messageError:  target.counter(
      metric='adapter-incoming-panic',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
    ),
  },
  systemDelay: {
    ecuLockUnlockDelay: target.timers(
      metric='unlock-via-power-control-duration',
      filters=target.combineFilters(filters.manufacturer, filters.firmware)
    ),
    batteryLockDelay: target.timers(
      metric='unlock-battery-hatch-timing',
      filters=target.combineFilters(filters.manufacturer, filters.firmware)
    ),
    helmetLockDelay: target.timers(
      metric='helmet-lock-timing',
      filters=target.combineFilters(filters.manufacturer, filters.firmware)
    ),
  },
  volumeTraffic: {
    countAll: target.gauges(
      'vehicle-operator',
      filters=target.combineFilters(filters.manufacturer, filters.firmware),
      withServiceFilters=false,
    ),
    received: target.counter(
      metric='adapter-incoming',
      filters=target.combineFilters(
        filters.firmware,
        filters.manufacturer,
      ),
      groupBys=['cmd'],
    ),
    send: target.counter(
      metric='device-outgoing',
      filters=target.combineFilters(
        filters.firmware,
        filters.manufacturer,
      ),
      groupBys=['cmd_outgoing'],
    ),
  },
  businessVolume: {
    startTrip: target.counter(
      metric='start-trip',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    startTripHelmetUnlocked: target.counter(
      metric='trip-helmet-unlock',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    riderEndTripLocked: target.counter(
      metric='rider-end-trip-lock-success',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    adminEndTripLocked: target.counter(
      metric='admin-end-trip-lock-success',
      withServiceFilters=false,
      filters=target.combineFilters(beamAPIFilter, target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    riderTripReview1: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 1)), target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    riderTripReview2: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 2)), target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    riderTripReview3: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 3)), target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    riderTripReview4: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 4)), target.combineFilters(filters.manufacturer, filters.firmware))
    ),
    riderTripReview5: target.counter(
      metric='rider-trip-review',
      withServiceFilters=false,
      filters=target.combineFilters(target.combineFilters(beamAPIFilter, target.equalsFilter('trip_review', 5)), target.combineFilters(filters.manufacturer, filters.firmware))
    ),
  },
  businessLatency: {
      vehicleUnlockLatency: target.timers(
        metric='start-trip-timing',
        filters=target.combineFilters(filters.manufacturer, filters.firmware)
      ),
      batteryHatchUnlockLatency: target.timers(
        metric='battery-hatch-open-latency',
        filters=target.combineFilters(filters.manufacturer, filters.firmware)
      ),
      helmetUnlockLatency: target.timers(
        metric='helmet-unlock-latency',
        filters=target.combineFilters(filters.manufacturer, filters.firmware)
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
      targets.systemDelay.ecuLockUnlockDelay,
    ]),
    batteryLockDelay: panel.timeLinear('Battery Lock Delay').addTargets([
      targets.systemDelay.batteryLockDelay,
    ]),
    helmetLockDelay: panel.timeLinear('Helmet Lock Delay').addTargets([
      targets.systemDelay.helmetLockDelay,
    ]),
  },
  volumeTraffic: {
    vehicleCount: panel.counter('Vehicle Count').addTargets([
      targets.volumeTraffic.countAll,
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
        targets.businessLatency.vehicleUnlockLatency,
      ]),
      batteryHatchUnlockLatency: panel.timeLinear('Battery Hatch Unlock Latency').addTargets([
        targets.businessLatency.batteryHatchUnlockLatency,
      ]),
      helmetUnlockLatency: panel.timeLinear('Helmet Unlock Latency').addTargets([
        targets.businessLatency.helmetUnlockLatency,
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
    query='omni,okai,omnigen3',
    allValues='.*',
    current='All',
    includeAll=true,
  )
)

.addTemplate(
  template.new(
    name='firmware',
    datasource=null,
    query='label_values(adapter_incoming, firmware)',
    allValues='.*',
    current='All',
    includeAll=true,
    refresh=1,
    sort=1,
  )
)

.addRows([
  rows.systemError,
  rows.systemDelay,
  rows.volumeTraffic,
  rows.businessVolume,
  rows.businessLatency,
])
