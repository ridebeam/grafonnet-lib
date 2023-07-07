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

// Context + Response + Condition

local filters = {
  contextCompleteSignUp: target.likeFilter('context', 'completeSignUp'),

  responseBlock: target.likeFilter('response', 'block'),
  responseAllow: target.likeFilter('response', 'allow'),

  conditionInvalidFraudDataFormat: target.likeFilter('condition', 'InvalidFraudDataFormat'),
  conditionVerificationFailed: target.likeFilter('condition', 'VerificationFailed'),
  conditionFraudDataIsNull: target.likeFilter('condition', 'fraudDataIsNull'),
  conditionWhitelistedUtilNotNullAndInFuture: target.likeFilter('condition', 'whitelistedUtilNotNullAndInFuture'),
  conditionAccountCreationCountGreaterThanAccountCreationLimit: target.likeFilter('condition', 'accountCreationLimit'),
  conditionAccountUsageCountGreaterThanAccountUsageLimit: target.likeFilter('condition', 'accountUsageLimit'),
  conditionAccountCreationCountAndAccountUsageCountLessThanAccountUsageLimit: target.likeFilter('condition', 'limitsOK'),
};

local targets = {
  requests: {
    completeSignUpAllowInvalidFraudDataFormat: 
    {
      expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"InvalidFraudDataFormat", response=~"allow"}))' + '[$__interval]',
      intervalFactor: 1,
      legendFormat: "{{condition}}",
      refId: "A"
    },
    completeSignUpAllowVerificationFailed: 
    {
      expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"VerificationFailed", response=~"allow"}))' + '[$__interval]',
      intervalFactor: 1,
      legendFormat: "{{condition}}",
      refId: "B"
    },
    completeSignUpAllowFraudDataIsNull: 
    {
      expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"fraudDataIsNull", response=~"allow"}))' + '[$__interval]',
      intervalFactor: 1,
      legendFormat: "{{condition}}",
      refId: "C"
    },
    completeSignUpAllowWhitelistedUtilNotNullAndInFuture: 
    {
      expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"whitelistedUtilNotNullAndInFuture", response=~"allow"}))' + '[$__interval]',
      intervalFactor: 1,
      legendFormat: "{{condition}}",
      refId: "D"
    },
    completeSignUpAllowAccountCreationCountAndAccountUsageCountLessThanAccountUsageLimit: 
    {
      expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"limitsOK", response=~"allow"}))' + '[$__interval]',
      intervalFactor: 1,
      legendFormat: "{{condition}}",
      refId: "E"
    },
    completeSignUpBlockAccountCreationCountGreaterThanAccountCreationLimit: 
    {
      expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"accountCreationLimit", response=~"block"}))' + '[$__interval]',
      intervalFactor: 1,
      legendFormat: "{{condition}}",
      refId: "F"
    },
    completeSignUpBlockAccountUsageCountGreaterThanAccountUsageLimit: 
    {
      expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"accountUsageLimit", response=~"block"}))' + '[$__interval]',
      intervalFactor: 1,
      legendFormat: "{{condition}}",
      refId: "G"
    },
  },
  resources: {
    cpuUsage: libProm.target(
      'sum(system_cpu_usage{namespace="$env"}) by (pod_name) * 100',
      legendFormat='{{pod_name}}',
    ),
    ramUsage: libProm.target(
      '( sum(avg_over_time(jvm_memory_used_bytes{area="heap", namespace="$env"}[1m])) by (pod_name) * 100 ) / ( sum(avg_over_time(jvm_memory_max_bytes{area="heap", namespace="$env"}[1m]))by(application, pod_name) )',
      legendFormat='{{pod_name}}',
    )
  }
};

local panels = {
  general: {
    completeSignUpAllowInvalidFraudDataFormatCount: panel.counter('Complete Sign Up Allow Invalid Fraud Data Format').addTargets([
      targets.requests.completeSignUpAllowInvalidFraudDataFormat,
    ]),
    completeSignUpAllowVerificationFailedCount: panel.counter('Complete Sign Up Allow Verification Failed').addTargets([
      targets.requests.completeSignUpAllowInvalidFraudDataFormat,
    ]),
    completeSignUpAllowFraudDataIsNullCount: panel.counter('Complete Sign Up Allow Fraud Data Is Null ').addTargets([
      targets.requests.completeSignUpAllowFraudDataIsNull,
    ]),
    completeSignUpAllowWhitelistedUtilNotNullAndInFutureCount: panel.counter('Complete Sign Up Allow Whitelisted Util Not Null And In Future').addTargets([
      targets.requests.completeSignUpAllowWhitelistedUtilNotNullAndInFuture,
    ]),
    completeSignUpAllowAccountCreationCountAndAccountUsageCountLessThanAccountUsageLimitCount: panel.counter('Complete Sign Up Allow When Limits OK').addTargets([
      targets.requests.completeSignUpAllowAccountCreationCountAndAccountUsageCountLessThanAccountUsageLimit,
    ]),
    completeSignUpBlockAccountCreationCountGreaterThanAccountCreationLimitCount: panel.counter('Complete Sign Up Block Account Creation Count Greater Than Account Creation Limit').addTargets([
      targets.requests.completeSignUpBlockAccountCreationCountGreaterThanAccountCreationLimit,
    ]),
    completeSignUpBlockAccountUsageCountGreaterThanAccountUsageLimitCount: panel.counter('Complete Sign Up Block Account Usage Count Greater Than Account Usage Limit').addTargets([
      targets.requests.completeSignUpBlockAccountUsageCountGreaterThanAccountUsageLimit,
    ]),
  },
  resourceUsage: {
    cpuUsage: panel.new("CPU Usage").addTargets([
        targets.resources.cpuUsage
    ]),
    ramUsage: panel.new("RAM Usage").addTargets([
        targets.resources.ramUsage
    ]),
  }
};

local rows = {
  general: row.new('General').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.completeSignUpAllowInvalidFraudDataFormatCount,
      panels.general.completeSignUpAllowInvalidFraudDataFormatCount,
      panels.general.completeSignUpAllowFraudDataIsNullCount,
      panels.general.completeSignUpAllowWhitelistedUtilNotNullAndInFutureCount,
      panels.general.completeSignUpAllowAccountCreationCountAndAccountUsageCountLessThanAccountUsageLimitCount,
      panels.general.completeSignUpBlockAccountCreationCountGreaterThanAccountCreationLimitCount,
      panels.general.completeSignUpBlockAccountUsageCountGreaterThanAccountUsageLimitCount,
    ]
  ]),
  resourceUsage: row.new('Resource Usage').addPanels([
    panel.halfRow(p)
    for p in [
      panels.resourceUsage.cpuUsage,
      panels.resourceUsage.ramUsage,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Fraud Overview',
  uid='fraud_overview',
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
    current='stable',
  )
)
.addTemplate(
  template.custom(
    name='context',
    query='completeSignUp',
    current='completeSignUp',
  )
)
.addRows([
  rows.general,
  rows.resourceUsage,
])
