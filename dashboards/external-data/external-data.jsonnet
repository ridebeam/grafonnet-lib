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
          metric='http_requests_count_total',
        )
      ),
      panel.counter('HTTP Errors', legend_show=true).addTargets([
        target.counter(
          metric='http_error_5xx_count_total',
        ),
        target.counter(
          metric='http_error_4xx_count_total',
        ),
      ]),
      panel.timeLinear('Latency', legend_show=true).addTargets([
        target.timers(
          metric='http_request_latency_ms',
        ).p99,
        target.timers(
          metric='http_request_latency_ms',
        ).p95,
      ]),
    ]
  ]),
])
