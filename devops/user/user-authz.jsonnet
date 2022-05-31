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
  getPermissionsForUser: {
    attempt: target.counter(
      metric='get-permissions-for-user-attempt',
    ),
    success: target.counter(
      metric='get-permissions-for-user-success',
    ),
    failed: target.counter(
      metric='get-permissions-for-user-failed',
    ),
    timing: target.timers(
      metric='get-permissions-for-user-timing',
    ),
  },
};

local panels = {
  general: {
    getPermissionsForUserCount: panel.counter('Get Permissisons For User Counts').addTargets([
      targets.getPermissionsForUser.attempt,
      targets.getPermissionsForUser.success,
      targets.getPermissionsForUser.failed,
    ]),
    getPermissionsForUserTiming: panel.timeLinear('Get Permissisons For User Timing').addTargets([
      targets.getPermissionsForUser.timing.p99,
      targets.getPermissionsForUser.timing.p95,
      targets.getPermissionsForUser.timing.p50,
    ]),
  },
};

local rows = {
  general: row.new('General').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.getPermissionsForUserCount,
      panels.general.getPermissionsForUserTiming,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'user-authz',
  uid='user_user-authz',
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
    query='user-authz',
    current='user-authz',
    hide='variable',
  )
)

.addRows([
  k8s.rows.service,
  panel.collapseRow(k8s.rows.grpc),
  rows.general,
])
