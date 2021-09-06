local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local panel = import '../../helper/panel.libsonnet';
local gcp = import '../../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;
local k8s = import '../k8s.libsonnet';

local targets = {
  getPermissionsForUser: {
    attempt: gcp.counter(
      metric=m('get-permissions-for-user-attempt'),
    ),
    success: gcp.counter(
      metric=m('get-permissions-for-user-success'),
    ),
    failed: gcp.counter(
      metric=m('get-permissions-for-user-failed'),
    ),
    timing: gcp.timers(
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
  'user-prod',
  uid='user-prod_user-authz',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

  .addTemplate(
    template.custom(
      name='env',
      query='production',
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
    panel.collapseRow(k8s.rows.http),
    rows.general,
  ])
