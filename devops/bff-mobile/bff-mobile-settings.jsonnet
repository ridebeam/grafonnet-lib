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
    getSettingTiming: target.timers(
      metric='beam-api-request-timing',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/systemSettings/getAllVer1')),
      withServiceFilters=false,
    ),
    getUserTiming: target.timers(
      metric='beam-api-request-timing',
      groupBys=['beam_api_request_url'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('beam_api_request_url', '/api/users')),
      withServiceFilters=false,
    ),
  },
  GQL: {
    getAppDataTiming: target.timers(
      metric='gql-request-timing',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'GetAppData')),
      withServiceFilters=false,
    ),
    getAppDataNoAuthTiming: target.timers(
      metric='gql-request-timing',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'GetAppDataNoAuth')),
      withServiceFilters=false,
    ),
    getAppDataError: target.counter(
      metric='gql-request-error',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'GetAppData')),
      withServiceFilters=false,
    ),
    getAppDataNoAuthError: target.counter(
      metric='gql-request-error',
      groupBys=['gql_operation_name'],
      filters=target.combineFilters(serviceFilters, target.equalsFilter('gql_operation_name', 'GetAppDataNoAuth')),
      withServiceFilters=false,
    ),
  },
};

local rows = [
  row.new('GraphQL').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLinear('[P50] App Data Latency').addTargets([
        metrics.BeamApi.getSettingTiming.p50,
        metrics.BeamApi.getUserTiming.p50,
        metrics.GQL.getAppDataTiming.p50,
        metrics.GQL.getAppDataNoAuthTiming.p50,
      ]),
      panel.timeLinear('[P90] App Data Latency').addTargets([
        metrics.BeamApi.getSettingTiming.p90,
        metrics.BeamApi.getUserTiming.p90,
        metrics.GQL.getAppDataTiming.p90,
        metrics.GQL.getAppDataNoAuthTiming.p90,
      ]),
      panel.timeLinear('[P95] App Data Latency').addTargets([
        metrics.BeamApi.getSettingTiming.p95,
        metrics.BeamApi.getUserTiming.p95,
        metrics.GQL.getAppDataTiming.p95,
        metrics.GQL.getAppDataNoAuthTiming.p95,
      ]),
      panel.timeLinear('[P99] App Data Latency').addTargets([
        metrics.BeamApi.getSettingTiming.p99,
        metrics.BeamApi.getUserTiming.p99,
        metrics.GQL.getAppDataTiming.p99,
        metrics.GQL.getAppDataNoAuthTiming.p99,
      ]),
      panel.counter('Get App Data No Auth Error Alert').addTargets([
        metrics.GQL.getAppDataError,
      ]).addAlert(
        name='Get App Data No Auth Error Alert',
        forDuration='5m',
        frequency='1m',
        message="Get App Data No Auth Error count is above 0.1",
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
  'bff-mobile-settings',
  uid='bff-mobile-settings',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows(
  rows,
)
