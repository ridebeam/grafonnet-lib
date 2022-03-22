local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local prom = import '../../helper/promql.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';

local helpers = prom.init();
local target = helpers.target;

local env = 'production';
local service = 'wallet';
local commonMsg = 'Please check the playbook page and look for the corresponding alert code: https://beammobility.atlassian.net/wiki/spaces/BE/pages/2441674761/Wallet+Service+Alert+Playbook';

local endpointAlerts = [
  {
    row: 'Endpoint',
    alerts: [
      {
        title: '[wallet-001] Unexpected Internal Error',
        custom: {
          name: 'Unexpected Internal Error ${grpc_server_method}',
          query: |||
            sum(delta(grpc_io_server_completed_rpcs{namespace="%(env)s", service="%(service)s", grpc_server_status="INTERNAL"}[1m])) by (grpc_server_method)
          ||| % { env: env, service: service },
          alias: '{{grpc_server_method}}',
        },
        threshold: 10,
        message: 'Unexpected errors more than 10 times in the last 5 minutes.' + commonMsg,
      },
      {
        title: '[wallet-002] p95 Latency',
        custom: {
          name: 'p95 Latency ${grpc_server_method}',
          query: |||
            histogram_quantile(0.95, sum(rate(grpc_io_server_server_latency_bucket{namespace="%(env)s", service="%(service)s"}[1m])) by (le, grpc_server_method))
          ||| % { env: env, service: service },
          alias: '{{grpc_server_method}}',
        },
        threshold: 10000,
        message: 'p95 latency is greater than 10s in the last 5 minutes. ' + commonMsg,
      },
    ],
  },
];

local jobAlerts = [
  {
    row: 'Expiring Job',
    alerts: [
      {
        title: '[wallet-003] No Expiring Job Triggered',
        custom: {
          name: 'no-expiring-job-triggered',
          query: |||
            sum(delta(grpc_io_server_completed_rpcs{namespace="%(env)s", service="%(service)s", grpc_server_method="ridebeam.user.Wallet/RunExpiryJob"}))
          ||| % { env: env, service: service },
          alias: 'Job Trigger',
        },
        threshold: 1,
        thresholdType: 'lt',
        message: 'No expiring job triggered in the last 15 minutes. ' + commonMsg,
      },
      {
        title: '[wallet-004] Expiring Job Error',
        custom: {
          name: 'Expiring Job Error',
          query: |||
            sum(delta(job_expiring_failed{namespace="%(env)s", service="%(service)s"}))
          ||| % { env: env, service: service },
          alias: 'Credit error',
        },
        threshold: 10,
        message: 'Expiring credit errors more than 10 times in the last 15 minutes. ' + commonMsg,
      },
    ],
  },
];

grafana.dashboard.new(
  'Wallet Production Alerts',
  uid='wallet_alert',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(
  alerts.createRows(endpointAlerts, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.productionAlerts,
      reducerType: 'sum',
    }
  })
)
.addRows(
  alerts.createRows(jobAlerts, alerts.defaults {
    alerts+: {
      channels: alerts.notifications.productionAlerts,
      queryTimeStart: '15m',
      reducerType: 'sum',
    }
  })
)