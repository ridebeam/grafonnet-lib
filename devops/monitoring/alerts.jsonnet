local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local alerts = import '../../helper/alerts.libsonnet';

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Monitoring Components',
    alerts: [
      {
        title: 'VictoriaMetrics Free Disk(GB)',
        custom: {
          name: 'Free Disk Capacity',
          query: |||
            vm_free_disk_space_bytes{job="%(job)s", instance="%(instance)s"}/1024/1024/1024
          ||| % { job: 'victoria-metrics', instance: 'self' },
          alias: 'free space(GB)',
        },
        // 100 GB
        threshold: 100,
        evaluateFor: '60m',
        thresholdType: 'lt',
        message: 'Disk space is under threshold 100GB, please extend it',
      },
    ],
  },
  {
    row: 'Kubernetes',
    alerts: [
      {
        title: 'Staging: CrashLoopBackOff Count',
        custom: {
          name: 'CrashLoopBackOff Count',
          query: |||
            increase(kube_pod_container_status_restarts_total{cluster="staging-sg",exported_namespace=~"staging|stable"}[10m]) > 0
          |||,
          alias: '{{cluster}} - {{exported_namespace}} -- {{pod}}',
        },
        // 1 times
        threshold: 1,
        evaluateFor: '10m',
        noDataState: 'ok',
        message: |||
          CrashLoopBackOff 1 time over 10 mins.
        |||,
      },
      {
        title: 'Core: CrashLoopBackOff Count',
        custom: {
          name: 'CrashLoopBackOff Count',
          query: |||
            increase(kube_pod_container_status_restarts_total{cluster="core-sg",exported_namespace=~"production"}[10m]) > 0
          |||,
          alias: '{{cluster}} - {{exported_namespace}} -- {{pod}}',
        },
        // 1 times
        threshold: 1,
        evaluateFor: '10m',
        noDataState: 'ok',
        message: |||
          CrashLoopBackOff 1 time over 10 mins.
        |||,
      },
    ],
  },
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'generic',
  uid='monitoring_victoriametrics',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(alertDefinitions, alerts.defaults {
  alerts+: {
    channels: [alerts.slackWarn],
  },
}))
