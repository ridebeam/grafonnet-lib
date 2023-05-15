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

local filters = {
  okStatus: target.likeFilter('status', '200'),
  errorStatus: target.likeFilter('status', '500'),
  badStatus: target.likeFilter('status', '400'),
  unauthorizedStatus: target.likeFilter('status', '401'),
  forbiddenStatus: target.likeFilter('status', '403'),
  notFoundStatus: target.likeFilter('status', '404'),
  requestRoute: target.likeFilter('route', '/api/.+'),
};

local targets = {
  requests: {
    succesStatus: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.requestRoute, filters.okStatus),
    ),
    failedStatus: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.requestRoute, filters.errorStatus),
    ),
    badStatus: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.requestRoute, filters.badStatus),
    ),
    unauthorizedStatus: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.requestRoute, filters.unauthorizedStatus),
    ),
    forbiddenStatus: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.requestRoute, filters.forbiddenStatus),
    ),
    notFoundStatus: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.requestRoute, filters.notFoundStatus),
    ),
  },
  resources: {
    cpuUsage: libProm.target(
      'sum(system_cpu_usage{namespace="$env", service="$service"}) by (pod_name) * 100',
      legendFormat='{{pod_name}}'
    ),
    ramUsage: libProm.target(
      '( sum(avg_over_time(jvm_memory_used_bytes{area="heap", namespace="$env", service="$service"}[1m])) by (pod_name) * 100 ) / ( sum(avg_over_time(jvm_memory_max_bytes{area="heap", namespace="$env", service="$service"}[1m]))by(application, pod_name) )',
      legendFormat='{{pod_name}}',
    )
  }
};

local panels = {
  general: {
    successCount: panel.counter('Success Requests').addTargets([
      targets.requests.succesStatus,
    ]),
    failedCount: panel.counter('Failed Requests').addTargets([
      targets.requests.failedStatus,
    ]),
    badCount: panel.counter('Bad Requests').addTargets([
      targets.requests.badStatus,
    ]),
    unauthorizedCount: panel.counter('Unauthorized Request').addTargets([
      targets.requests.unauthorizedStatus,
    ]),
    forbiddenCount: panel.counter('Forbidden Requests').addTargets([
      targets.requests.forbiddenStatus,
    ]),
    notFoundCount: panel.counter('Not Found Requests').addTargets([
      targets.requests.notFoundStatus,
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
      panels.general.successCount,
      panels.general.failedCount,
      panels.general.badCount,
      panels.general.unauthorizedCount,
      panels.general.forbiddenCount,
      panels.general.notFoundCount,
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
  'Franchise Overview',
  uid='franchise_overview',
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
    name='service',
    query='franchise',
    current='franchise',
  )
)
.addRows([
  rows.general,
  rows.resourceUsage,
])
