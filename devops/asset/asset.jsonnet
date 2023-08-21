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

local filters = {
  okStatus: target.likeFilter('status', '200'),
  errorStatus: target.likeFilter('status', '500'),
  atRiskLostRoute: target.likeFilter('route', '/asset/vehicles/atRiskLost/{cityId}'),
  atRiskUnrepairableRoute: target.likeFilter('route', '/asset/vehicles/atRiskUnrepairable/{cityId}'),
  confirmLostRoute: target.likeFilter('route', '/asset/vehicles/confirmLost/{vehicleId}'),
  confirmUnrepairableRoute: target.likeFilter('route', '/asset/vehicles/confirmUnrepairable/{vehicleId}'),
  p99: target.likeFilter('quantile', '0.99'),
  p95: target.likeFilter('quantile', '0.95'),
  p90: target.likeFilter('quantile', '0.9'),
  p50: target.likeFilter('quantile', '0.5'),
};

local targets = {
  atRiskLost: {
    success: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.atRiskLostRoute, filters.okStatus),
    ),
    failed: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.atRiskLostRoute, filters.errorStatus),
    ),
  },
  atRiskUnrepairable: {
    success: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.atRiskUnrepairableRoute, filters.okStatus),
    ),
    failed: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.atRiskUnrepairableRoute, filters.errorStatus),
    ),
  },
  confirmLost: {
    success: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.confirmLostRoute, filters.okStatus),
    ),
    failed: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.confirmLostRoute, filters.errorStatus),
    ),
  },
  confirmUnrepairable: {
    success: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.confirmUnrepairableRoute, filters.okStatus),
    ),
    failed: target.counter(
      metric='ktor_http_server_requests_seconds_count',
      filters=target.combineFilters(filters.confirmUnrepairableRoute, filters.errorStatus),
    ),
  },
};

local panels = {
  general: {
    atRiskLostCount: panel.counter('At Risk Lost Vehicle').addTargets([
      targets.atRiskLost.success,
      targets.atRiskLost.failed,
    ]),
    atRiskUnrepairableCount: panel.counter('At Risk Unrepairable Vehicle').addTargets([
      targets.atRiskUnrepairable.success,
      targets.atRiskUnrepairable.failed,
    ]),
    confirmLostCount: panel.counter('Confirm Lost Vehicle').addTargets([
      targets.confirmLost.success,
      targets.confirmLost.failed,
    ]),
    confirmUnrepairableCount: panel.counter('Confirm Unrepairable Vehicle').addTargets([
      targets.confirmUnrepairable.success,
      targets.confirmUnrepairable.failed,
    ]),
  },
};

local rows = {
  general: row.new('General').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.atRiskLostCount,
      panels.general.atRiskUnrepairableCount,
      panels.general.confirmLostCount,
      panels.general.confirmUnrepairableCount,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Asset Overview',
  uid='asset_overview',
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
    name='service',
    query='asset',
    current='asset',
  )
)
.addRows([
  rows.general,
])