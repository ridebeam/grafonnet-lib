local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';
local alertsHelper = import '../../helper/alerts.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;
local serviceFilters = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'bff-mobile'),
);

local metrics = {
  BeamApi: {
    startTripTiming: target.timers(
      metric='beam-api-request-timing',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips')),
      withServiceFilters=false,
    ),
    endTripTiming: target.timers(
      metric='beam-api-request-timing',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips/endtrip/xxx')),
      withServiceFilters=false,
    ),
    currentTripTiming: target.timers(
      metric='beam-api-request-timing',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips/current')),
      withServiceFilters=false,
    ),
    payUnpaidTripTiming: target.timers(
      metric='beam-api-request-timing',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips/unPaid')),
      withServiceFilters=false,
    ),
    startTripSuccess: target.counter(
      metric='beam-api-request-handled',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips')),
      withServiceFilters=false,
    ),
    endTripSuccess: target.counter(
      metric='beam-api-request-handled',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips/endtrip/xxx')),
      withServiceFilters=false,
    ),
    currentTripSuccess: target.counter(
      metric='beam-api-request-handled',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips/current')),
      withServiceFilters=false,
    ),
    startTripError: target.counter(
      metric='beam-api-request-error',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips')),
      withServiceFilters=false,
    ),
    endTripError: target.counter(
      metric='beam-api-request-error',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips/endtrip/xxx')),
      withServiceFilters=false,
    ),
    currentTripError: target.counter(
      metric='beam-api-request-error',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/trips/current')),
      withServiceFilters=false,
    ),
  },
  GQL: {
    startTripTiming: target.timers(
      metric='gql-request-timing',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'StartTrip')),
      withServiceFilters=false,
    ),
    endTripTiming: target.timers(
      metric='gql-request-timing',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'EndTrip')),
      withServiceFilters=false,
    ),
    startTripError: target.counter(
      metric='gql-request-error',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'StartTrip')),
      withServiceFilters=false,
    ),
    endTripError: target.counter(
      metric='gql-request-error',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'EndTrip')),
      withServiceFilters=false,
    ),
    getAppDataError: target.counter(
      metric='gql-request-error',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'GetAppData')),
      withServiceFilters=false,
    ),
  },
};

local rows = [
  row.new('GraphQL').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLinear('[P50] Trips Latency').addTargets([
        metrics.BeamApi.startTripTiming.p50,
        metrics.BeamApi.endTripTiming.p50,
        metrics.BeamApi.currentTripTiming.p50,
        metrics.BeamApi.payUnpaidTripTiming.p50,
        metrics.GQL.startTripTiming.p50,
        metrics.GQL.endTripTiming.p50,
      ]),
      panel.timeLinear('[P90] Trips Latency').addTargets([
        metrics.BeamApi.startTripTiming.p90,
        metrics.BeamApi.endTripTiming.p90,
        metrics.BeamApi.currentTripTiming.p90,
        metrics.BeamApi.payUnpaidTripTiming.p90,
        metrics.GQL.startTripTiming.p90,
        metrics.GQL.endTripTiming.p90,
      ]),
      panel.timeLinear('[P95] Trips Latency').addTargets([
        metrics.BeamApi.startTripTiming.p95,
        metrics.BeamApi.endTripTiming.p95,
        metrics.BeamApi.currentTripTiming.p95,
        metrics.BeamApi.payUnpaidTripTiming.p95,
        metrics.GQL.startTripTiming.p95,
        metrics.GQL.endTripTiming.p95,
      ]),
      panel.timeLinear('[P99] Trips Latency').addTargets([
        metrics.BeamApi.startTripTiming.p99,
        metrics.BeamApi.endTripTiming.p99,
        metrics.BeamApi.currentTripTiming.p99,
        metrics.BeamApi.payUnpaidTripTiming.p99,
        metrics.GQL.startTripTiming.p99,
        metrics.GQL.endTripTiming.p99,
      ]),
      panel.counter('Trips Success').addTargets([
        metrics.BeamApi.startTripSuccess,
        metrics.BeamApi.endTripSuccess,
        metrics.BeamApi.currentTripSuccess,
      ]),
      panel.counter('Trips Error').addTargets([
        metrics.GQL.startTripError,
        metrics.GQL.endTripError,
        metrics.GQL.getAppDataError,
        metrics.BeamApi.currentTripError,
      ]),
      panel.timeLinear('Start Trip Alert Latency').addTargets([
        metrics.GQL.startTripTiming.p90,
      ]).addAlert(
        name='Start Trip Latency Alert',
        forDuration='5m',
        frequency='1m',
        message="Start Trip Latency is above 10",
        notifications=[alertsHelper.slackTrips],
      ).addConditions([{
        type: 'query',
        query: {
          params: [
            'A',
            '5m',
            'now',
          ],
        },
        reducer: {
          type: 'max',
          params: [],
        },
        evaluator: {
          type: 'gt',
          params: [
            10,
          ],
        },
      }]),
      panel.timeLinear('End Trip Alert Latency').addTargets([
        metrics.GQL.endTripTiming.p90,
      ]).addAlert(
        name='End Trip Latency Alert',
        forDuration='5m',
        frequency='1m',
        message="End Trip Latency is above 10",
        notifications=[alertsHelper.slackTrips],
      ).addConditions([{
        type: 'query',
        query: {
          params: [
            'A',
            '5m',
            'now',
          ],
        },
        reducer: {
          type: 'max',
          params: [],
        },
        evaluator: {
          type: 'gt',
          params: [
            10,
          ],
        },
      }]),
      panel.counter('Start Trip Error Alert').addTargets([
        metrics.GQL.startTripError,
      ]).addAlert(
        name='Start Trip Error Alert',
        forDuration='5m',
        frequency='1m',
        message="Start Trip Error count is above 2",
        notifications=[alertsHelper.slackTrips],
      ).addConditions([{
        type: 'query',
        query: {
          params: [
            'A',
            '5m',
            'now',
          ],
        },
        reducer: {
          type: 'max',
          params: [],
        },
        evaluator: {
          type: 'gt',
          params: [
            2,
          ],
        },
      }]),
      panel.counter('End Trip Error Alert').addTargets([
        metrics.GQL.endTripError,
      ]).addAlert(
        name='End Trip Error Alert',
        forDuration='5m',
        frequency='1m',
        message="End Trip Error count is above 0.25",
        notifications=[alertsHelper.slackTrips],
        noDataState='ok',
      ).addConditions([{
        type: 'query',
        query: {
          params: [
            'A',
            '5m',
            'now',
          ],
        },
        reducer: {
          type: 'max',
          params: [],
        },
        evaluator: {
          type: 'gt',
          params: [
            0.35,
          ],
        },
      }]),
      panel.counter('Get App Data Error Alert').addTargets([
        metrics.GQL.getAppDataError,
      ]).addAlert(
        name='Get App Data Error Alert',
        forDuration='5m',
        frequency='1m',
        message="Get App Data Error count is above 0.1",
        notifications=[alertsHelper.slackTrips],
        noDataState='ok',
      ).addConditions([{
        type: 'query',
        query: {
          params: [
            'A',
            '5m',
            'now',
          ],
        },
        reducer: {
          type: 'max',
          params: [],
        },
        evaluator: {
          type: 'gt',
          params: [
            0.1,
          ],
        },
      }]),
    ]
  ]),
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'bff-mobile-trips',
  uid='bff-mobile-trips',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows(
  rows,
)
