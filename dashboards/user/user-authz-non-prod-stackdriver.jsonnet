local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local k8s_helper = import '../k8s.libsonnet';
local gcp = import '../../helper/gcp.libsonnet';

local k8s = k8s_helper.init('ridebeam-core-staging');
local helpers = gcp.init('ridebeam-core-staging');
local target = helpers.target;
local panel = helpers.panel;
local m = target.customMetric;
local l = target.label;

local targets = {
  getPermissionsForUser: {
    attempt: target.counter(
      metric=m('get-permissions-for-user-attempt'),
    ),
    success: target.counter(
      metric=m('get-permissions-for-user-success'),
    ),
    failed: target.counter(
      metric=m('get-permissions-for-user-failed'),
    ),
    timing: target.timers(
      metric=m('get-permissions-for-user-timing'),
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
    getPermissionsForUserTiming: panel.timeLinear('Get Permissisons For User Timing (Avg)').addTargets([
      targets.getPermissionsForUser.timing.avg,
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
  'user-non-prod',
  uid='user-non-prod_user-authz',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,staging',
    current='staging',
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
  panel.collapseRow(k8s.rows.http),
  rows.general,
])
