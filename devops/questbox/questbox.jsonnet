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

local targets = {
  getTaskForVehicle: {
    attempt: target.counter(
      metric='questbox-get-task-vehicle-attempts',
    ),
    success: target.counter(
      metric='questbox-get-task-vehicle-success',
    ),
    failed: target.counter(
      metric='questbox-get-task-vehicle-failure',
    ),
    timing: target.timers(
      metric='questbox-get-task-vehicle-timing',
    ),
  },
  getTaskForUser: {
    attempt: target.counter(
      metric='questbox-get-task-user-attempt',
    ),
    success: target.counter(
      metric='questbox-get-task-user-success',
    ),
    failed: target.counter(
      metric='questbox-get-task-user-failed',
    ),
    timing: target.timers(
      metric='questbox-get-task-user-timing',
    ),
  },
  applyAction: {
    attempt: target.counter(
      metric='questbox-apply-action-attempt',
    ),
    success: target.counter(
      metric='questbox-apply-action-success',
    ),
    failed: target.counter(
      metric='questbox-apply-action-failed',
    ),
    timing: target.timers(
      metric='questbox-apply-action-timing',
    ),
  },
};

local panels = {
  general: {
    getTaskForVehicleCount: panel.counter('Get Task For Vehicle Counts').addTargets([
      targets.getTaskForVehicle.attempt,
      targets.getTaskForVehicle.success,
      targets.getTaskForVehicle.failed,
    ]),
    getTaskForUserCount: panel.counter('Get Task For User Counts').addTargets([
      targets.getTaskForUser.attempt,
      targets.getTaskForUser.success,
      targets.getTaskForUser.failed,
    ]),
    applyActionCount: panel.counter('Apply Action Counts').addTargets([
      targets.applyAction.attempt,
      targets.applyAction.success,
      targets.applyAction.failed,
    ]),
    getTaskForVehicleTiming: panel.timeLinear('Get Tasks For Vehicle Timing').addTargets([
      targets.getTaskForVehicle.timing.p99,
      targets.getTaskForVehicle.timing.p95,
      targets.getTaskForVehicle.timing.p50,
    ]),
    getTaskForUserTiming: panel.timeLinear('Get Tasks For User Timing').addTargets([
      targets.getTaskForUser.timing.p99,
      targets.getTaskForUser.timing.p95,
      targets.getTaskForUser.timing.p50,
    ]),
    applyActionTiming: panel.timeLinear('Apply Action Timing').addTargets([
      targets.applyAction.timing.p99,
      targets.applyAction.timing.p95,
      targets.applyAction.timing.p50,
    ]),
  },
};

local rows = {
  general: row.new('General').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.getTaskForVehicleCount,
      panels.general.getTaskForVehicleTiming,
      panels.general.getTaskForUserCount,
      panels.general.getTaskForUserTiming,
      panels.general.applyActionCount,
      panels.general.applyActionTiming,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Questbox Overview',
  uid='questbox_overview',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='namespace',
    query='production',
    current='production',
  )
)

.addRows([
  rows.general,
])
