local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

local targets = {
  createBusinessProfile: {
    attempt: target.counter(
      metric='business-profile-create-request-total',
    ),
    success: target.counter(
      metric='business-profile-create-success-total',
    ),
    failure: target.counter(
      metric='business-profile-create-failed-total',
    ),
  },
  redeemActivationCode: {
    attempt: target.counter(
      metric='activation-code-redeem-attempt-total',
    ),
    success: target.counter(
      metric='activation-code-redeem-success-total',
    ),
    failure: target.counter(
      metric='activation-code-redeem-failed-total',
    ),
  },
  deleteBusinessUser: {
    attempt: target.counter(
      metric='delete-business-user-attempt-total',
    ),
    success: target.counter(
      metric='delete-business-user-success-total',
    ),
    failure: target.counter(
      metric='delete-business-user-failed-total',
    ),
  },
};


local panels = {
  service: {
    createBusinessProfileCounts: panel.counter('Create Business Profile Counts').addTargets([
      targets.createBusinessProfile.attempt,
      targets.createBusinessProfile.success,
    ]),
    redeemActivationCodeCounts: panel.counter('Redeem Activation Code Counts').addTargets([
      targets.createBusinessProfile.attempt,
      targets.createBusinessProfile.success,
    ]),
    deleteBusinessUserCounts: panel.counter('Delete Business User Counts').addTargets([
      targets.deleteBusinessUser.attempt,
      targets.deleteBusinessUser.success,
    ]),
  },
  errors: {
    general: panel.counter('Errors').addTargets([
      targets.createBusinessProfile.failure,
      targets.redeemActivationCode.failure,
      targets.deleteBusinessUser.failure,
    ]),
  },
};

local rows = {
  businessProfile: row.new('Business Profile').addPanels([
    panel.halfRow(p)
    for p in [
      panels.service.createBusinessProfileCounts,
    ]
  ]),
  businessUser: row.new('Business User').addPanels([
    panel.halfRow(p)
    for p in [
      panels.service.redeemActivationCodeCounts,
      panels.service.deleteBusinessUserCounts,
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
  'Beam For Business Overview',
  uid='beam-for-business-overview',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)
.addTemplate(
  template.custom(
    name='env',
    query='stable,staging,production',
    current='production',
  )
)
.addTemplate(
  template.custom(
    name='service',
    query='beam-for-business',
    current='beam-for-business',
    hide='variable',
  )
)
.addRows([
  rows.businessProfile,
  rows.businessUser,
  rows.errors,
])
