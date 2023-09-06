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

// TODO: filter not needed?
local filters = {
  contextOTPSignUp: target.likeFilter('context', 'beam-api-phoneverification'),
  contextSSOSignUp: target.likeFilter('context', 'user-profile-loginWithSSO'),

  responseBlock: target.likeFilter('response', 'block'),
  responseAllow: target.likeFilter('response', 'allow'),

  conditionFraudDataFormatTooOld: target.likeFilter('condition', 'FraudDataFormatTooOld'),
  conditionInvalidFraudDataFormat: target.likeFilter('condition', 'InvalidFraudDataFormat'),
  conditionAccountCreationCountLessThanAccountCreationLimit: target.likeFilter('condition', 'OK'),
  conditionAccountCreationCountGreaterThanEqualsToAccountCreationLimit: target.likeFilter('condition', 'accountCreationLimit'),
  conditionFraudDataIsNull: target.likeFilter('condition', 'fraudDataIsNull'),
  conditionHasUnpaidTrip: target.likeFilter('condition', 'hasUnpaidTrip'),
  conditionAccountCreationCountAndAccountUsageCountLessThanAccountUsageLimit: target.likeFilter('condition', 'limitsOK'),
  conditionWhitelistedUtilNotNullAndInFuture: target.likeFilter('condition', 'whitelistedUtilNotNullAndInFuture'),
  conditionAccountUsageCountGreaterThanEqualsToAccountUsageLimit: target.likeFilter('condition', 'accountUsageLimit'),
};

local fraudServiceTargetsData = [
  {
    "name": "AllowAccountCreationCountLessThanAccountCreationLimit",
    "condition": "OK",
    "response": "allow",
    "refId": "A",
    "panelDisplayHeading":"Allow Account Creation Count Less-Than Account Creation Limit: Type - Allow",
  },
  {
    "name": "AllowAccountCreationCountAndAccountUsageCountLessThanAccountUsageLimit",
    "condition": "limitsOK",
    "response": "allow",
    "refId": "B",
    "panelDisplayHeading":"Allow Account Creation Count And Account Usage Count Less-Than Account Usage Limit: Type - Allow [Obsolete]]"
  },
  {
    "name": "AllowWhitelistedUtilNotNullAndInFuture",
    "condition": "whitelistedUtilNotNullAndInFuture",
    "response": "allow",
    "refId": "C",
    "panelDisplayHeading":"Whitelisted Util Not Null And In Future: Type - Allow"
  },
  {
    "name": "BlockFraudDataFormatTooOld",
    "condition": "FraudDataFormatTooOld",
    "response": "block",
    "refId": "D",
    "panelDisplayHeading":"Fraud Data Format Too Old: Type - Block"
  },
  {
    "name": "BlockInvalidFraudDataFormat",
    "condition": "InvalidFraudDataFormat",
    "response": "block",
    "refId": "E",
    "panelDisplayHeading":"Invalid Fraud Data Format: Type - Block"
  },
  {
    "name": "BlockFraudDataIsNull",
    "condition": "fraudDataIsNull",
    "response": "block",
    "refId": "F",
    "panelDisplayHeading":"Fraud Data Is Null: Type - Block"
  },
  {
    "name": "BlockHasUnpaidTrip",
    "condition": "hasUnpaidTrip",
    "response": "block",
    "refId": "G",
    "panelDisplayHeading":"Has Unpaid Trip: Type - Block"
  },
  {
    "name": "BlockAccountCreationCountGreaterThanEqualsToAccountCreationLimit",
    "condition": "accountCreationLimit",
    "response": "block",
    "refId": "H",
    "panelDisplayHeading":"Account Creation Count Greater-Than-Equals-To Account Creation Limit: Type - Block"
  },
  {
    "name": "BlockAccountUsageCountGreaterThanEqualsToAccountUsageLimit",
    "condition": "accountUsageLimit",
    "response": "block",
    "refId": "I",
    "panelDisplayHeading":"Account Usage Count Greater-Than-Equals-To Account Usage Limit: Type - Block"
  }
];

local userProfileServiceTargetsData = [
  {
    "name": "LoginCheckAllow",
    "metric": "fraud_check_at_login_allow",
    "refId": "A",
    "panelDisplayHeading": "SSO Login Check: Type - Allow"
  },
  {
    "name": "LoginCheckBlock",
    "metric": "fraud_check_at_login_block",
    "refId": "B",
    "panelDisplayHeading": "SSO Login Check: Type - Block"
  },
  {
    "name": "AccountCreationCheckAllow",
    "metric": "fraud_check_at_sso_allow",
    "refId": "C",
    "panelDisplayHeading": "SSO Account Creation Check: Type - Allow"
  },
  {
    "name": "AccountCreationCheckBlock",
    "metric": "fraud_check_at_sso_block",
    "refId": "D",
    "panelDisplayHeading": "SSO Account Creation Check: Type - Block"
  },
  {
    "name": "CheckSendToFraudServiceSuccess",
    "metric": "fraud_check_sso_success",
    "refId": "E",
    "panelDisplayHeading": "SSO Check Request to Fraud Service: Type - Success"
  },
  {
    "name": "CheckSendToFraudServiceFailed",
    "metric": "fraud_check_sso_failed",
    "refId": "F",
    "panelDisplayHeading": "SSO Check Request to Fraud Service: Type - Failed"
  }
];

local fraudServiceRequestsData = {
  [item.name]: {
    expr: 'sum(rate(fraud_service_total{namespace="$env", context="$context", condition=~"' + item.condition + '", response=~"' + item.response + '"}))' + '[$__interval]',
    intervalFactor: 1,
    legendFormat: "{{condition}}",
    refId: item.refId
  }
  for item in fraudServiceTargetsData
};

local userProfileServiceRequestsData = {
  [item.name]: {
    expr: 'sum(rate(' + item.metric + '{namespace="$env"}))' + '[$__interval]',
    intervalFactor: 1,
    legendFormat: "{{condition}}",
    refId: item.refId
  }
  for item in userProfileServiceTargetsData
};

local targets = {
  fraudServiceRequests: fraudServiceRequestsData,
  userProfileServiceRequests: userProfileServiceRequestsData,
  resources: {
    cpuUsage: libProm.target(
      'sum(system_cpu_usage{namespace="$env", service="$service"}) by (pod_name) * 100',
      legendFormat='{{pod_name}}',
    ),
    ramUsage: libProm.target(
      '( sum(avg_over_time(jvm_memory_used_bytes{area="heap", namespace="$env", service="$service"}[1m])) by (pod_name) * 100 ) / ( sum(avg_over_time(jvm_memory_max_bytes{area="heap", namespace="$env"}[1m]))by(application, pod_name) )',
      legendFormat='{{pod_name}}',
    )
  }
};

local fraudServiceData = {
  [item.name + "Count"]: panel.counter(item.panelDisplayHeading).addTargets([
    targets.fraudServiceRequests[item.name],
  ])
  for item in fraudServiceTargetsData
};

local userProfileServiceData = {
  [item.name + "Count"]: panel.counter(item.panelDisplayHeading).addTargets([
    targets.userProfileServiceRequests[item.name],
  ])
  for item in userProfileServiceTargetsData
};

local panels = {
  fraudService: fraudServiceData,
  userProfileService: userProfileServiceData,
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
  fraudService: row.new('Fraud Service - API Calls').addPanels([
    panel.halfRow(p)
      for p in std.objectValues(panels.fraudService)
  ]),
  userProfileService: row.new('User Profile Service - SSO flow').addPanels([
    panel.halfRow(p)
      for p in std.objectValues(panels.userProfileService)
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
    current='production',
  )
)
.addTemplate(
  template.custom(
    name='context',
    query='beam-api-phoneverification,user-profile-loginWithSSO',
    current='user-profile-loginWithSSO',
  )
)
.addTemplate(
  template.custom(
    name='service',
    query='fraud-service,user-profile',
    current='fraud-service',
  )
)
.addRows([
  rows.fraudService,
  rows.userProfileService,
  rows.resourceUsage,
])
