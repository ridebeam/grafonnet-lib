local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local gcp = import '../../helper/gcp.libsonnet';
local gcpHelpers = gcp.init('ridebeam-core');
local gcpTarget = gcpHelpers.target;
local gcpPanel = gcpHelpers.panel;
local m = gcpTarget.customMetric;
local l = gcpTarget.label;


// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'flink-jwebb-clickhouse-jobmanager'),
);


// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Flink Health',
    alerts: [
      {
        title: 'Downtime > 0',
        counter: { name: 'flink_jobmanager_job_downtime' },
        threshold: 0,
        reducerType: 'sum',
        evaluateFor: '10m',
        message: 'Flink Job is down',
      },
    ],
  },
  {
      row: 'Flink Checkpoints',
      alerts: [
        {
          title: 'Flink checkpoint failure > 0',
          counter: { name: 'flink_jobmanager_job_numberOfFailedCheckpoints' },
          threshold: 0,
          message: 'Flink Checkpoint has failed',
        },
      ],
    }
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'JWebb Alerts',
  uid='jwebb_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slackData],
  },
  counters+: {
    func: 'delta',
    filters: serviceFilter,
  },
  gcpGauges+: {
    gcpHelpers: gcpHelpers,
  },
  gauges+: {
    filters: serviceFilter,
  },
}))
