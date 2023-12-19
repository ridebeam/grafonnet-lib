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
    getBenefitsTiming: target.timers(
      metric='get-segmentation-benefits-latency',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    getBenefitsSuccess: target.counter(
      metric='get-segmentation-benefits-success',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    getBenefitsFailure: target.counter(
      metric='get-segmentation-benefits-failed',
      filters=serviceFilters,
      withServiceFilters=false,
    ),

    createUserSegmentationsTiming: target.timers(
      metric='create-user-segmentations-latency',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    createUserSegmentationsSuccess: target.counter(
      metric='create-user-segmentations-success',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
    createUserSegmentationsFailure: target.counter(
      metric='create-user-segmentations-failed',
      filters=serviceFilters,
      withServiceFilters=false,
    ),
  },
};

local rows = [
  row.new('GraphQL').addPanels([
    panel.halfRow(p)
    for p in [
      panel.timeLinear('[beam-api] Get Benefits Latency').addTargets([
        metrics.BeamApi.getBenefitsTiming.p50,
        metrics.BeamApi.getBenefitsTiming.p90,
      ]),
      panel.counter('[beam-api] Get Benefits').addTargets([
        metrics.BeamApi.getBenefitsSuccess,
        metrics.BeamApi.getBenefitsFailure,
      ]),

      panel.timeLinear('[segmentation] Get Benefits Latency').addTargets([
        metrics.Segmentation.getBenefitsTiming.p50,
        metrics.Segmentation.getBenefitsTiming.p90,
      ]),
      panel.counter('[segmenetation] Get Benefits').addTargets([
        metrics.Segmentation.getBenefitsSuccess,
        metrics.Segmentation.getBenefitsFailure,
      ]),

      panel.timeLinear('[segmentation] Create User Segmentations Latency').addTargets([
        metrics.Segmentation.createUserSegmentationsTiming.p50,
        metrics.Segmentation.createUserSegmentationsTiming.p90,
      ]),
      panel.counter('[segmenetation] Get Benefits').addTargets([
        metrics.Segmentation.createUserSegmentationsSuccess,
        metrics.Segmentation.createUserSegmentationsFailure,
      ]),
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
