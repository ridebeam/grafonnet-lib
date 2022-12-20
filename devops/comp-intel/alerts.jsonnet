local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local env = 'production';
local service = 'comp-intel';

// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', env),
  target.equalsFilter('service', service),
);

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Job Timer',
    alerts: [
      {
        title: 'Timer (Seconds)',
        custom: {
          name: 'Vehicle Scraped Number',
          query: |||
            sum(delta(compintel_scrape_duration_sum{namespace="%(env)s", service="%(service)s"}[1m])) by (competitor)
          ||| % { env: env, service: service },
          alias: '{{Vehicle Number}}',
        },
        threshold: 1200,
        evaluateFor: '60m',
        message: 'Comp-intel took too long',
      },
    ],
  },
  {
    row: 'Vehicle Scraping',
    alerts: [
      {
        title: 'Vehicle Scraped (Vehicles) - Only Beam',
        custom: {
          name: 'Vehicle Scraped Number',
          query: |||
            sum(delta(compintel_scrape_vehicles_sum{competitor=~"beam_.*", namespace="%(env)s", service="%(service)s"}[30m])) by (competitor)
          ||| % { env: env, service: service },
          alias: '{{Vehicle Number}}',
        },
        threshold: 5,
        thresholdType: 'lt',
        evaluateEvery: '1m',
        evaluateFor: '30m',
        message: 'Some Report Scraped NONE SCOOTERS : Only Beam',
      },
    ],
  },
  {
    row: 'Vehicle Scraping',
    alerts: [
      {
        title: 'Vehicle Scraped (Vehicles) - All except Beam',
        custom: {
          name: 'Vehicle Scraped Number',
          query: |||
            sum(delta(compintel_scrape_vehicles_sum{competitor!~"beam_.*", namespace="%(env)s", service="%(service)s"}[60m])) by (competitor)
          ||| % { env: env, service: service },
          alias: '{{Vehicle Number}}',
        },
        threshold: 5,
        thresholdType: 'lt',
        evaluateEvery: '1m',
        evaluateFor: '60m',
        message: 'Some Report Scraped NONE SCOOTERS : All except Beam',
      },
    ],
  },

];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Comp-Intel Alerts',
  uid='comp-intel_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slackCompIntel],
  },
}))
