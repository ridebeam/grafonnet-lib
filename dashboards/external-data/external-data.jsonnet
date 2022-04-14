local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'External Data API Overview',
  uid='external-data-api',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='external-data-api',
    current='external-data-api',
    hide='variable',
  )
)

.addRows([
  row.new('Service Overview').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('Requests', legend_show=true).addTarget(
        target.counter(
          metric='istio_requests_total',
          filters=target.combineFilters(
            target.equalsFilter('reporter', 'source'), target.combineFilters(
              target.equalsFilter('destination_service_name', 'external-data-api-http'),
              target.equalsFilter('destination_service_namespace', '$env'),
            ),
          ),
          withServiceFilters=false,
        )
      ),
      panel.counter('HTTP Errors', legend_show=true).addTargets([
        target.ratio(
          metric='istio_requests_total',
          filters=target.combineFilters(
            target.equalsFilter('reporter', 'source'), target.combineFilters(
              target.equalsFilter('destination_service_name', 'external-data-api-http'),
              target.equalsFilter('destination_service_namespace', '$env'),
            ),
          ),
          numeratorFilters=target.likeFilter('response_code', '5..'),
          withServiceFilters=false,
          alias='5xx',
        ),
        target.ratio(
          metric='istio_requests_total',
          filters=target.combineFilters(
            target.equalsFilter('reporter', 'source'), target.combineFilters(
              target.equalsFilter('destination_service_name', 'external-data-api-http'),
              target.equalsFilter('destination_service_namespace', '$env'),
            ),
          ),
          numeratorFilters=target.likeFilter('response_code', '4..'),
          withServiceFilters=false,
          alias='4xx',
        ),
      ]),
      panel.timeLinear('Latency', format='ms', legend_show=true).addTargets([
        target.timers(
          'istio_request_duration_milliseconds',
          filters=target.combineFilters(
            target.equalsFilter('reporter', 'source'), target.combineFilters(
              target.equalsFilter('destination_service_name', 'external-data-api-http'),
              target.equalsFilter('destination_service_namespace', '$env'),
            ),
          ),
          intervalFactor=4,
          withServiceFilters=false,
        ).p99,
        target.timers(
          'istio_request_duration_milliseconds',
          filters=target.combineFilters(
            target.equalsFilter('reporter', 'source'), target.combineFilters(
              target.equalsFilter('destination_service_name', 'external-data-api-http'),
              target.equalsFilter('destination_service_namespace', '$env'),
            ),
          ),
          intervalFactor=4,
          withServiceFilters=false,
        ).p95,
      ]),
    ]
  ]),
])
