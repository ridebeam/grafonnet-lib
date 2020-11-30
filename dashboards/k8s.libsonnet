local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local panel = import '../helper/panel.libsonnet';
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
        filterPods=true,
      ),
      mem: gcp.gauges(
        'kubernetes.io/container/memory/used_bytes',
        filterPods=true,
      ),
      log: gcp.target(
        metric='logging.googleapis.com/log_entry_count',
        metricKind='DELTA',
        reducer='REDUCE_SUM',
        aligner='ALIGN_RATE',
        groupBys=['metric.label.severity'],
        valueType='INT64',
        filterPods=true,
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
      cpu: panel.timeLinear('CPU Usage').addTarget($.targets.process.cpu),
      mem: panel.new('Memory Usage', 'bytes').addTarget($.targets.process.mem.sum),
      goroutines: panel.new('Go Routines').addTargets([
        $.targets.golang.goroutines.avg,
        $.targets.golang.goroutines.max,
      ]),
      log: panel.new('Log Output').addTarget($.targets.process.log),
    },
    http: {
      latency: panel.timeLinear('Latency', format='ms').addTargets([
        $.targets.http.latency.p99,
        $.targets.http.latency.p50,
        $.targets.http.latency.avg,
      ]),
      status: panel.counter('Status Codes').addTarget($.targets.http.status),
    },
    kafka: {
      consume: panel.counter('Consumed').addTarget($.targets.kafka.consume),
      lag: panel.timeLog2('Consumer Lag').addTarget($.targets.kafka.lag.p99),
      produce: panel.counter('Produced').addTarget($.targets.kafka.produce),
      errors: panel.counter('Producer Errors').addTarget($.targets.kafka.errors),
    },
    postgres: {
      connections: panel.new('Connections').addTargets([
        $.targets.postgres.connections.open.sum,
        $.targets.postgres.connections.idle.sum,
        $.targets.postgres.connections.active.sum,
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