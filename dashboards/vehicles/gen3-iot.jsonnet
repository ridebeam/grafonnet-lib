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
  }
};

local panels = {
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
};

local rows = {
  systemError: row.new('System Errors').addPanels([
    panel.halfRow(p)
    for p in [
      panels.lockUnlockError,
      panels.invalidData,
      panels.errorCodes,
      panels.alarm,
      panels.disconnection,
      panels.firmware,
      panels.messageError,
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
])
