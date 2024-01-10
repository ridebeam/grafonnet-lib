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
local serviceFilters = target.equalsFilter('namespace', '$env');

local metrics = {
  BeamApi: {
    getBenefitsTiming: target.timers(
      metric='segmentation-get-benefits-latency',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    getBenefitsSuccess: target.counter(
      metric='segmentation-get-benefits-success',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    getBenefitsFailure: target.counter(
      metric='segmentation-get-benefits-failure',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
  },
  Segmentation: {
    getBenefitsTiming: target.counter(
      metric='get-segmentation-benefits-latency-seconds',
      filters=serviceFilters,
      withServiceFilters=false,
      groupBys=['quantile'],
    ),
    getBenefitsSuccess: target.counter(
      metric='get-segmentation-benefits-success-total',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    getBenefitsFailure: target.counter(
      metric='get-segmentation-benefits-failed-total',
      filters=serviceFilters,
      withServiceFilters=false,
    ),

    upsertSegmentationTiming: target.counter(
      metric='upsert-segmentation-latency-seconds',
      filters=serviceFilters,
      withServiceFilters=false,
      groupBys=['quantile'],
    ),
    upsertSegmentationSuccess: target.counter(
      metric='upsert-segmentation-success-total',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    upsertSegmentationFailure: target.counter(
      metric='upsert-segmentation-failed-total',
      filters=serviceFilters,
      withServiceFilters=false,
    ),

    createUserSegmentationsTiming: target.counter(
      metric='create-user-segmentations-latency-seconds',
      filters=serviceFilters,
      withServiceFilters=false,
      groupBys=['quantile'],
    ),
    createUserSegmentationsSuccess: target.counter(
      metric='create-user-segmentations-success-total',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    createUserSegmentationsFailure: target.counter(
      metric='create-user-segmentations-failed-total',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
  },
};

local rows = [
  row.new('beam-api').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLinear('[beam-api] Get Benefits Latency').addTargets([
        metrics.BeamApi.getBenefitsTiming.p50,
        metrics.BeamApi.getBenefitsTiming.p90,
        metrics.BeamApi.getBenefitsTiming.p95,
        metrics.BeamApi.getBenefitsTiming.p99,
      ]),
      panel.counter('[beam-api] Get Benefits').addTargets([
        metrics.BeamApi.getBenefitsSuccess,
        metrics.BeamApi.getBenefitsFailure,
      ]),
    ]
  ]),
  row.new('segmentation').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLinear('[segmentation] Get Benefits Latency').addTargets([
        metrics.Segmentation.getBenefitsTiming,
      ]),
      panel.counter('[segmenetation] Get Benefits').addTargets([
        metrics.Segmentation.getBenefitsSuccess,
        metrics.Segmentation.getBenefitsFailure,
      ]),

      panel.timeLinear('[segmentation] Upsert Segemntation Latency').addTargets([
        metrics.Segmentation.upsertSegmentationTiming,
      ]),
      panel.counter('[segmenetation] Upsert Segmentation').addTargets([
        metrics.Segmentation.upsertSegmentationSuccess,
        metrics.Segmentation.upsertSegmentationFailure,
      ]),

      panel.timeLinear('[segmentation] Create User Segmentations Latency').addTargets([
        metrics.Segmentation.createUserSegmentationsTiming,
      ]),
      panel.counter('[segmenetation] Create User Segmentations').addTargets([
        metrics.Segmentation.createUserSegmentationsSuccess,
        metrics.Segmentation.createUserSegmentationsFailure,
      ]),
    ]
  ]),
  row.new('alerts').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLinear('Get Benefits Latency').addTargets([
        metrics.BeamApi.getBenefitsTiming.p95,
      ]).addAlert(
        name='Get Benefits Latency',
        forDuration='5m',
        frequency='1m',
        message="Get Benefits Latency Is Above 1s",
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
            1,
          ],
        },
      }]),
    ]
  ]),
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'segmentations',
  uid='segmentations',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows(
  rows,
)

.addTemplate(
  template.custom(
    name='env',
    query='stable,staging,production',
    current='production',
  )
)
