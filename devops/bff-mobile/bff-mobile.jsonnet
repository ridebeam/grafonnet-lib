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

local metircs = {
  GraphQL: {
    successOverall: target.counter(
      metric='gql-request-handled',
    ),
    success: target.counter(
      metric='gql-request-handled',
      groupBys=['gql_operation_name']
    ),
    failedOverall: target.counter(
      metric='gql-request-error',
    ),
    failed: target.counter(
      metric='gql-request-error',
      groupBys=['gql_operation_name']
    ),
    timingOverall: target.timers(
      metric='gql-request-timing',
    ),
    timing: target.timers(
      metric='gql-request-timing',
      groupBys=['gql_operation_name']
    ),
  },
  BeamApi: {
    successOverall: target.counter(
      metric='beam-api-request-handled',
    ),
    success: target.counter(
      metric='beam-api-request-handled',
      groupBys=['beam_api_request_url']
    ),
    failedOverall: target.counter(
      metric='beam-api-request-error',
    ),
    failed: target.counter(
      metric='beam-api-request-error',
      groupBys=['beam_api_request_url']
    ),
    timingOverall: target.timers(
      metric='beam-api-request-timing',
    ),
    timing: target.timers(
      metric='beam-api-request-timing',
      groupBys=['beam_api_request_url']
    ),
  },
};


local rows = [
  row.new('GraphQL').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('GraphQL Request Overall (Handled)').addTargets([
        metircs.GraphQL.successOverall,
      ]),
      panel.counter('GraphQL Request (Handled)').addTargets([
        metircs.GraphQL.success,
      ]),
      panel.counter('GraphQL Request Overall (Error)').addTargets([
        metircs.GraphQL.failedOverall,
      ]),
      panel.counter('GraphQL Request (Error)').addTargets([
        metircs.GraphQL.failed,
      ]),
      panel.timeLinear('GraphQL Request Timing Overall').addTargets([
        metircs.GraphQL.timingOverall.p50,
        metircs.GraphQL.timingOverall.p95,
        metircs.GraphQL.timingOverall.p99,
      ]),
      panel.timeLinear('GraphQL Request Timing').addTargets([
        metircs.GraphQL.timing.p95,
      ]),
    ]
  ]),
  row.new('Beam API').addPanels([
    panel.halfRow(p)
    for p in [
      panel.counter('Beam API Request Overall (Handled)').addTargets([
        metircs.BeamApi.successOverall,
      ]),
      panel.counter('Beam API Request (Handled)').addTargets([
        metircs.BeamApi.success,
      ]),
      panel.counter('Beam API Request Overall (Error)').addTargets([
        metircs.BeamApi.failedOverall,
      ]),
      panel.counter('Beam API Request (Error)').addTargets([
        metircs.BeamApi.failed,
      ]),
      panel.timeLinear('Beam API Request Timing Overall').addTargets([
        metircs.BeamApi.timingOverall.p50,
        metircs.BeamApi.timingOverall.p95,
        metircs.BeamApi.timingOverall.p99,
      ]),
      panel.timeLinear('Beam API Request Timing').addTargets([
        metircs.BeamApi.timing.p95,
      ]),
    ]
  ]),
];


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'bff-mobile',
  uid='bff-mobile',
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
    query='bff-mobile',
    current='bff-mobile',
    hide='variable',
  )
)

.addRows(
  [
    k8s.rows.service,
    panel.collapseRow(k8s.rows.grpc),
  ]
  + rows,
)
