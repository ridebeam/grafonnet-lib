local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local panel = import '../helper/panel.libsonnet';
local target = import '../helper/target.libsonnet';
local gcp = import '../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;

{
  targets: {
    process: {
      cpu: gcp.counter(
        alias='CPU usage',
        metric='kubernetes.io/container/cpu/core_usage_time',
        unit='s',
        valueType='DOUBLE',
      ),
      mem: gcp.gauges(
        'kubernetes.io/container/memory/used_bytes',
        filters=gcp.equalsFilter(l('memory_type'), 'non-evictable'),
      ),
      log: gcp.target(
        metric='logging.googleapis.com/log_entry_count',
        metricKind='DELTA',
        reducer='REDUCE_SUM',
        aligner='ALIGN_RATE',
        groupBys=['metric.label.severity'],
        valueType='INT64',
      ),
    },
    golang: {
      goroutines: gcp.gauges(m('process/cpu_goroutines')),
    },
    http: {
      latency: gcp.timers(m('opencensus.io/http/server/latency')),
      status: gcp.counter(
        metric=m('opencensus.io/http/server/response_count_by_status_code'),
        groupBys=[l('http_status')],
      ),
    },
    grpc: {
      latency: gcp.timers(m('grpc.io/server/server_latency')),
      status: gcp.counter(
        metric=m('grpc.io/server/completed_rpcs'),
        groupBys=[l('grpc_server_status')],
      ),
    },
    kafka: {
      consume: gcp.counter(
        metric=m('kafka-consume'),
        groupBys=[l('kafka_source_topic')],
      ),
      lag: gcp.timers(
        metric=m('kafka-consume-lag'),
        groupBys=[l('kafka_source_topic')],
      ),
      produce: gcp.counter(
        metric=m('kafka-produce'),
        groupBys=[l('kafka_target_topic')],
      ),
      errors: gcp.counter(
        metric=m('kafka-produce-error'),
        groupBys=[l('kafka_target_topic')],
      ),
    },
    postgres: {
      connections: {
        open: gcp.gauges(m('go.sql/db/connections/open')),
        idle: gcp.gauges(m('go.sql/db/connections/idle')),
        active: gcp.gauges(m('go.sql/db/connections/active')),
      },
      latency: gcp.timers(
        metric=m('go.sql/client/latency'),
        groupBys=[l('go_sql_method')],
      ),
    },
  },
  panels: {
    service: {
      cpu: panel.timeLinear('CPU Usage', legend_show=false).addTarget($.targets.process.cpu),
      mem: panel.new('Memory Usage', 'bytes', false).addTarget($.targets.process.mem.sum),
      goroutines: panel.new('Go Routines').addTargets([
        $.targets.golang.goroutines.avg,
        $.targets.golang.goroutines.max,
      ]),
      log: panel.new('Log Output').addTarget($.targets.process.log)
        .addLink({
          title:'Logs Explorer',
          url:'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}%22%0Alabels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22${service}%22?project=vehicles-283509',
          targetBlank:true,
        })
        { options: {
            dataLinks: [{
               title: 'Logs Explorer for ${__series.name}',
               url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}%22%0Alabels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22${service}%22%0Aseverity%3D${__series.name}?project=vehicles-283509',
               targetBlank: true,
            }]
        }},
    },
    http: {
      latency: panel.timeLinear('Latency', format='ms').addTargets([
        $.targets.http.latency.p99,
        $.targets.http.latency.p50,
        $.targets.http.latency.avg,
      ]),
      status: panel.counter('Status Codes').addTarget($.targets.http.status),
    },
    grpc: {
      latency: panel.timeLinear('Latency', format='ms').addTargets([
        $.targets.grpc.latency.p99,
        $.targets.grpc.latency.p50,
        $.targets.grpc.latency.avg,
      ]),
      status: panel.counter('Status Codes').addTarget($.targets.grpc.status),
    },
    kafka: {
      consume: panel.counter('Consumed').addTarget($.targets.kafka.consume),
      lag: panel.timeLog2('Consumer Lag').addTarget($.targets.kafka.lag.p99),
      produce: panel.counter('Produced').addTarget($.targets.kafka.produce),
      errors: panel.counter('Producer Errors').addTarget($.targets.kafka.errors),
    },
    postgres: {
      connections: panel.new('Connections').addTargets([
        target.alias($.targets.postgres.connections.open.sum, "open"),
        target.alias($.targets.postgres.connections.idle.sum, "idle"),
        target.alias($.targets.postgres.connections.active.sum, "active"),
      ]),
      latency: panel.timeLinear('Latency', format='ms').addTarget($.targets.postgres.latency.p99),
    },
  },
  rows: {
    service: row.new('Service Overview')
      .addPanels([
        panel.halfRow(p)
        for p in [
          $.panels.service.cpu,
          $.panels.service.goroutines,
          $.panels.service.mem,
          $.panels.service.log,
        ]
      ]),
    http: row.new('HTTP')
      .addPanels([
        panel.halfRow(p)
        for p in [
          $.panels.http.latency,
          $.panels.http.status,
        ]
      ]),
    grpc: row.new('gRPC')
      .addPanels([
        panel.halfRow(p)
        for p in [
          $.panels.grpc.latency,
          $.panels.grpc.status,
        ]
      ]),
    kafka: row.new('Kafka')
      .addPanels([
        panel.halfRow(p)
        for p in [
          $.panels.kafka.consume,
          $.panels.kafka.lag,
          $.panels.kafka.produce,
          $.panels.kafka.errors,
        ]
      ]),
    postgres: row.new('Postgres')
      .addPanels([
        panel.halfRow(p)
        for p in [
          $.panels.postgres.latency,
          $.panels.postgres.connections,
        ]
      ]),
  },
}