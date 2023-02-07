local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

local targets = {
  addMember: {
    attempt: target.counter(
      metric='add-member-attempt',
    ),
    success: target.counter(
      metric='add-member-success',
    ),
    failure: target.counter(
      metric='add-member-failed',
    ),
    timing: target.timers(
      metric='add-member-timing',
    ),
  },
  getMemberInfo: {
     attempt: target.counter(
      metric='get-member-info-attempt',
    ),
    success: target.counter(
      metric='get-member-info-success',
    ),
    failure: target.counter(
      metric='get-member-info-failed',
    ),
    timing: target.timers(
      metric='get-member-info-timing',
    ),
  },
  applyBenefit: {
     attempt: target.counter(
      metric='apply-benefit-attempt',
    ),
    success: target.counter(
      metric='apply-benefit-success',
    ),
    failure: target.counter(
      metric='apply-benefit-failed',
    ),
    timing: target.timers(
      metric='apply-benefit-timing',
    ),
  },
};


local panels = {
  service: {
    addMemberCounts: panel.counter('Add Member Counts').addTargets([
      targets.addMember.attempt,
      targets.addMember.success,
    ]),
    getMemberInfoCounts: panel.counter('Get Member Info Counts').addTargets([
      targets.getMemberInfo.attempt,
      targets.getMemberInfo.success,
    ]),
    applyBenefitCounts: panel.counter('Apply Benefit Counts').addTargets([
      targets.applyBenefit.attempt,
      targets.applyBenefit.success,
    ]),
  },
  errors: {
    general: panel.counter('Errors').addTargets([
      targets.addMember.failure,
      targets.getMemberInfo.failure,
      targets.applyBenefit.failure,
    ]),
  },
};

local rows = {
  service: row.new('Loyalty').addPanels([
    panel.halfRow(p)
    for p in [
      panels.service.addMemberCounts,
      panels.service.getMemberInfoCounts,
      panels.service.applyBenefitCounts,
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
  'Loyalty Overview',
  uid='loyalty-overview',
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
    query='loyalty',
    current='loyalty',
    hide='variable',
  )
)
.addRows([
  rows.service,
  rows.errors,
])
