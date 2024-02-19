local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';


local targets = {
  claimPromoCode: {
    attempt: target.counter(
      metric='promo-code-claim-attempt-total',
    ),
    success: target.counter(
      metric='promo-code-claim-success-total',
    ),
    failure: target.counter(
      metric='promo-code-claim-failed-total',
    ),
  },
  getClaimablePromoCode: {
    attempt: target.counter(
      metric='promo-code-get-claimable-attempt-total',
    ),
    success: target.counter(
      metric='promo-code-get-claimable-success-total',
    ),
    failure: target.counter(
      metric='promo-code-get-claimable-failed-total',
    ),
  },
  getClaimedPromoCode: {
    attempt: target.counter(
      metric='promo-code-get-claimed-attempt-total',
    ),
    success: target.counter(
      metric='promo-code-get-claimed-success-total',
    ),
    failure: target.counter(
      metric='promo-code-get-claimed-failed-total',
    ),
  },
  getPastPromoCode: {
    attempt: target.counter(
      metric='promo-code-get-past-attempt-total',
    ),
    success: target.counter(
      metric='promo-code-get-past-success-total',
    ),
    failure: target.counter(
      metric='promo-code-get-past-failed-total',
    ),
  },
  getPromoCodeUserPrivileges: {
    attempt: target.counter(
      metric='promo-code-get-user-privileges-attempt-total',
    ),
    success: target.counter(
      metric='promo-code-get-user-privileges-success-total',
    ),
    failure: target.counter(
      metric='promo-code-get-user-privileges-failed-total',
    ),
  },
};


local panels = {
  service: {
    claimPromoCodeCounts: panel.counter('Claim Promo Code Counts').addTargets([
      targets.claimPromoCode.attempt,
      targets.claimPromoCode.success,
    ]),
    getClaimablePromoCodeCounts: panel.counter('Get Claimable Promo Code Counts').addTargets([
      targets.getClaimablePromoCode.attempt,
      targets.getClaimablePromoCode.success,
    ]),
    getClaimedPromoCodeCounts: panel.counter('Get Claimed Promo Code Counts').addTargets([
      targets.getClaimedPromoCode.attempt,
      targets.getClaimedPromoCode.success,
    ]),
    getPastPromoCodeCounts: panel.counter('Get Past Promo Code Counts').addTargets([
      targets.getPastPromoCode.attempt,
      targets.getPastPromoCode.success,
    ]),
    getPromoCodeUserPrivilegesCounts: panel.counter('Get Promo Code Privileges Counts').addTargets([
      targets.getPromoCodeUserPrivileges.attempt,
      targets.getPromoCodeUserPrivileges.success,
    ]),
    
  },
  errors: {
    general: panel.counter('Errors').addTargets([
      targets.claimPromoCode.failure,
      targets.getClaimablePromoCode.failure,
      targets.getClaimedPromoCode.failure,
      targets.getPastPromoCode.failure,
      targets.getPromoCodeUserPrivileges.failure,
    ]),
  },
};

local rows = {
  promoCode: row.new('Promo Code').addPanels([
    panel.halfRow(p)
    for p in [
      panels.service.claimPromoCodeCounts,
      panels.service.getClaimablePromoCodeCounts,
      panels.service.getClaimedPromoCodeCounts,
      panels.service.getPastPromoCodeCounts,
      panels.service.getPromoCodeUserPrivilegesCounts,
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
  'Promo Code Overview',
  uid='promo-code-overview',
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
    query='promo-code',
    current='promo-code',
    hide='variable',
  )
)
.addRows([
  rows.promoCode,
  rows.errors,
])
