local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local template = grafana.template;
local libProm = grafana.prometheus;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  tmoney: {
    requests: target.timeseries(
      alias='requests_seconds_count',
      metric='ktor_http_server_requests_seconds_count',
    ),
  },
};

local thresholds = [
  {
    color: 'green',
    value: null,
  },
  {
    color: 'orange',
    value: 50,
  },
  {
    color: 'red',
    value: 90,
  },
];

local panels = {
  tmoneyCounts: {
    failedCounts: panel.timeseries(
      title='T-Money Failed Count',
      description='Per-second average rate of failed requests',
      drawStyle='bars',
    ).addTarget(
      libProm.target(
        expr='sum(increase(ktor_http_server_requests_seconds_count{namespace="$env", service="bff-open-api", status!="200", route=~"/t-money/.+"}[$__interval])) by (route, status) > 0',
      )
    ),
    successCounts: panel.timeseries(
      title='T-Money Success Count',
      description='Per-second average rate of successful requests',
      drawStyle='bars',
    ).addTarget(
      libProm.target(
        expr='sum(increase(ktor_http_server_requests_seconds_count{namespace="$env", service="bff-open-api", status="200", route=~"/t-money/.+"}[$__interval])) by (route) > 0',
      )
    ),
  },
  tMoneyState: {
    failedPercent: panel.timeseries(
      title='T-Money Failed % (All and StartTrip)',
      description='Percent of requests that failed for all endpoints and start-trip',
      drawStyle='bars',
      thresholdsMode='percentage',
    ).addThresholds(thresholds).addTargets([
        libProm.target(
            expr='100 * sum(increase(ktor_http_server_requests_seconds_count{namespace="$env", service="bff-open-api", status!="200", route=~"/t-money/.+"}[$__interval]))/clamp_min(sum(increase(ktor_http_server_requests_seconds_count{namespace="$env", service="bff-open-api", route=~"/t-money/.+"}[$__interval])), 1)',
            ),
        libProm.target(
            expr='100 * sum(increase(ktor_http_server_requests_seconds_count{namespace="$env", service="bff-open-api", status!="200", route=~"/t-money/.+/startTrip"}[$__interval]))/clamp_min(sum(increase(ktor_http_server_requests_seconds_count{namespace="$env", service="bff-open-api", route=~"/t-money/.+/startTrip"}[$__interval])), 1)',
          ),
        ]),
    responseP95: panel.timeseries(
      title='Response (seconds) - P95').addTarget(
        libProm.target(
            expr='histogram_quantile(0.95, sum(rate(ktor_http_server_requests_seconds_bucket{namespace="$env", service="bff-open-api"}[$__interval])) by (le, route))',
            ),
        ),
  },
};

local rows = {
  counts: row.new('Counts').addPanels([
    panel.halfRow(p)
    for p in [
      panels.tmoneyCounts.failedCounts,
      panels.tmoneyCounts.successCounts,
    ]
  ]),
  state: row.new('State').addPanels([
    panel.halfRow(p)
    for p in [
      panels.tMoneyState.failedPercent,
      panels.tMoneyState.responseP95,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'bff-open-api',
  uid='RX_open_api_promql',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  editable=true,
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,stable,staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='bff-open-api',
    current='bff-open-api',
    hide='variable',
  )
)
.addRows([
  rows.counts,
  rows.state,
])
