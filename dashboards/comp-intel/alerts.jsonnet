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
        title: 'Vehicle Scraped (Vehicles)',
        custom: {
          name: 'Vehicle Scraped Number',
          query: |||
            sum(delta(compintel_scrape_vehicles_sum{namespace="%(env)s", service="%(service)s"}[1m])) by (competitor)
          ||| % { env: env, service: service },
          alias: '{{Vehicle Number}}',
        },
        threshold: 5,
        thresholdType: 'lt',
        evaluateFor: '60m',
        message: 'Some Report Scraped none scooter',
      },
    ],
  },
  {
    row: 'Proxy Rate Limit Hit',
    alerts: [
      {
        title: 'Rate Limit Hit',
        custom: {
          name: 'Rate Number',
          query: |||
            sum(delta(compintel_rate_limit_count{namespace="%(env)s", service="%(service)s"}[1m])) by (proxy)
          ||| % { env: env, service: service },
          alias: '{{Error Number}}',
        },
        threshold: 2000,
        evaluateFor: '60m',
        message: 'Some proxy is occurring high on limit rate',
      },
    ],
  },
  {
    row: 'Proxy Error 403',
    alerts: [
      {
        title: 'Error 403',
        custom: {
          name: 'Error 403',
          query: |||
            sum(delta(compintel_scrape_error_403{namespace="%(env)s", service="%(service)s"}[1m])) by (proxy)
          ||| % { env: env, service: service },
          alias: '{{Error Number}}',
        },
        threshold: 2000,
        evaluateFor: '60m',
        message: 'Some proxy is occurring high on error 403 ',
      },
    ],
  },

];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Comp-Intel Alerts',
  uid='comp_intel_alerts_prod',
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
