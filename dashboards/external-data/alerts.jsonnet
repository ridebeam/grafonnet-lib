local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';

local cloudwatchHelpers = import '../../helper/cloudwatch.libsonnet';
local cwHelpers = cloudwatchHelpers.init();
local cwPanel = cwHelpers.panel;

local alertDefaults = {
  format: 'short',
  channels: alerts.notifications.opsGRAlerts,
  thresholdType: 'gt',
  evaluateFor: '5m',
};


// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'API',
    alerts: [
      {
        title: 'Rate of HTTP 500s',
        cloudwatch: { namespace: 'AWS/ElasticBeanstalk', name: 'ApplicationRequests5xx', dimensions: { EnvironmentName: 'external-data-api-production' } },
        threshold: 0,
        message: '',  // TODO message
      },
//      {
//        title: 'HTTP Endpoint Latency P99',
//        cloudwatch: { namespace: 'AWS/ElasticBeanstalk', name: 'ApplicationLatencyP99', dimensions: { EnvironmentName: 'docker-production' } },
//        format: 's',
//        threshold: 10,
//        message: '',  // TODO message
//      },
//      {
//        title: 'Health Status - API',
//        cloudwatch: { namespace: 'AWS/ElasticBeanstalk', name: 'EnvironmentHealth', dimensions: { EnvironmentName: 'external-data-api-production' } },
//        threshold: 1,
//        message: '',  // TODO message
//      },
    ],
  },
];

// create a simple counter, with the metric name as alias
local createCloudwatchTarget(metric) = cloudwatch.target(
  region='default',
  namespace=metric.namespace,
  metric=metric.name,
  dimensions=metric.dimensions,
  period='auto',
);

local createTarget(alertDefinition) =
  if 'cloudwatch' in alertDefinition then
    createCloudwatchTarget(alertDefinition.cloudwatch)
  else {};

local panelHelper(alertDefinition) =
  if 'cloudwatch' in alertDefinition then
    cwPanel
  else {};

// create for each entry a counter panel with alert
// TODO move to helper
local createAlert(definition) =
  local def = alertDefaults + definition;
  [
    panelHelper(def).counter(def.title, format=def.format).addTargets([
      createTarget(def),
    ]).addAlert(
      def.title,
      notifications=def.channels,
      message='%s\n\n%s' % [def.title, def.message],
      forDuration=def.evaluateFor,
      frequency='1m',
    ).addConditions([
      alerts.newCondition(reducerType='avg', threshold=def.threshold, thresholdType=def.thresholdType),
    ]),
  ];

// create panels for each row and put two panels side by side
local rows = [
  row.new(r.row).addPanels([
    cwPanel.halfRow(p)
    for p in std.flattenArrays([
      createAlert(alert)
      for alert in r.alerts
    ])
  ])
  for r in alertDefinitions
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'External Data API Alerts',
  uid='external-data-api_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(rows)
