local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';
local libProm = grafana.prometheus;

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local envFilter = target.equalsFilter('namespace', '$env');

local fraudServiceTargets = {
  overall: target.delta(
    metric='fraud-service-total',
    groupBys=['context', 'response', 'condition'],
    filters=target.combineFilters(envFilter, target.notLikeFilter('condition', 'fraudDataIsNull|FraudDataFormatTooOld')),
    withServiceFilters=false,
  ),
};

local userProfileTargets = {
  loginAllows: target.delta(
    metric='fraud-check-at-login-allow',
    groupBys=['login_type'],
    filters=envFilter,
    alias='loginAllows',
    withServiceFilters=false,
  ),
  loginBlocks: target.delta(
    metric='fraud-check-at-login-block',
    groupBys=['login_type'],
    filters=envFilter,
    alias='loginBlocks',
    withServiceFilters=false,
  ),
  ssoSignUpAllows: target.delta(
    metric='fraud-check-at-sso-allow',
    filters=envFilter,
    alias='ssoSignUpAllows',
    withServiceFilters=false,
  ),
  ssoSignUpBlocks: target.delta(
    metric='fraud-check-at-sso-block',
    filters=envFilter,
    alias='ssoSignUpBlocks',
    withServiceFilters=false,
  ),
  httpCallsToFraudCheckSuccess: target.delta(
    metric='fraud-check-sso-success',
    filters=envFilter,
    alias='httpCallsToFraudCheckSuccess',
    withServiceFilters=false,
  ),
  httpCallsToFraudCheckFailed: target.delta(
    metric='fraud-check-sso-failed',
    filters=envFilter,
    alias='httpCallsToFraudCheckFailed',
    withServiceFilters=false,
  )
};

local rows = {
  fraudService: row.new('Fraud Service').addPanels([
    panel.fullRow(p)
    for p in [
      panel.counter('Fraud Checks Counts').addTargets([
        fraudServiceTargets.overall,
      ]),
    ]
  ]),
  userProfileService: row.new('User Profile Service').addPanels([
    panel.fullRow(p)
    for p in [
      panel.counter('User Profile Counts').addTargets([
        userProfileTargets.loginAllows,
        userProfileTargets.loginBlocks,
        userProfileTargets.ssoSignUpAllows,
        userProfileTargets.ssoSignUpBlocks,
        userProfileTargets.httpCallsToFraudCheckSuccess,
        userProfileTargets.httpCallsToFraudCheckFailed,
      ]),
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Fraud Overview Summary',
  uid='fraud_overview_summary',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addTemplate(
  template.custom(
    name='env',
    query='stable,staging,production',
    current='production',
  )
)
.addRows([
  rows.fraudService,
  rows.userProfileService,
])
