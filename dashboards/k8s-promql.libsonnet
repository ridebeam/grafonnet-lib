local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local panel = import '../helper/promql-panel.libsonnet';
local prom = import '../helper/promql-target.libsonnet';
local libProm = grafana.prometheus;

{
  targets: {
    process: {
      cpu: prom.counter(
        metric='container_cpu_usage_seconds_total',
        filters=prom.combineFilters(prom.equalsFilter('namespace', '$env'), prom.equalsFilter('container', '$service')),
        withServiceFilters=false,
      ),
      mem: prom.gauges(
        metric='container_memory_usage_bytes',
        filters=prom.combineFilters(prom.equalsFilter('namespace', '$env'), prom.equalsFilter('container', '$service')),
        withServiceFilters=false,
      ),
      log: libProm.target(
        // only an approximiation, as we can't get the individual data points, and it is stored as delta, instead of counter
        'sum(avg_over_time(stackdriver_k_8_s_container_logging_googleapis_com_log_entry_count{container_name="$service", namespace_name="$env"}[$__interval])) by (severity, project_id) > 0',
        legendFormat='{{severity}}',
      ),
    },
    golang: {
      goroutines: prom.gauges('process/cpu_goroutines'),
    },
    http: {
      latency: prom.timers('opencensus.io/http/server/latency'),
      status: prom.counter(
        metric='opencensus.io/http/server/response_count_by_status_code',
        groupBys=['http_status'],
      ),
    },
    grpc: {
      latency: prom.timers('grpc.io/server/server_latency'),
      status: prom.counter(
        metric='grpc.io/server/completed_rpcs',
        groupBys=['grpc_server_status'],
      ),
    },
    kafka: {
      consume: prom.counter(
        metric='kafka-consume',
        groupBys=['kafka_source_topic'],
      ),
      duration: prom.timers(
        metric='kafka-consume-duration',
        groupBys=['kafka_source_topic'],
      ),
      lag: prom.timers(
        metric='kafka-consume-lag',
        groupBys=['kafka_source_topic'],
      ),
      produce: prom.counter(
        metric='kafka-produce',
        groupBys=['kafka_target_topic'],
      ),
      errors: prom.counter(
        metric='kafka-produce-error',
        groupBys=['kafka_target_topic'],
      ),
      repartition: prom.counter(
        metric='kafka-consume-repartition',
        groupBys=['kafka_source_topic'],
      ),
    },
    postgres: {
      connections: {
        open: prom.gauges('go.sql/db/connections/open'),
        idle: prom.gauges('go.sql/db/connections/idle'),
        active: prom.gauges('go.sql/db/connections/active'),
      },
      latency: prom.timers(
        metric='go.sql/client/latency',
        groupBys=['go_sql_method'],
      ),
      calls: prom.counter(
        metric='go.sql/client/calls',
        groupBys=['go_sql_method'],
      ),
      errors: prom.counter('pg-put-error'),
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
      log: panel.new('Log Output (aprox entries per minute)').addTarget($.targets.process.log) {
        options: {
          dataLinks: [{
            title: 'Logs Explorer for ${__series.name}',
            url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}﻿%22%0Alabels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22﻿${service}﻿%22%0Aseverity%3D﻿${__series.name};timeRange=${__from:date}%2F${__to:date}﻿?project=﻿${__field.labels.project_id}',
            targetBlank: true,
          }],
        },
      },
    },
    http: {
      latency: panel.timeLinear('Latency', format='ms').addTargets([
        $.targets.http.latency.p99,
        $.targets.http.latency.p50,
      ]),
      status: panel.counter('Status Codes').addTarget($.targets.http.status),
    },
    grpc: {
      latency: panel.timeLinear('Latency', format='ms').addTargets([
        $.targets.grpc.latency.p99,
        $.targets.grpc.latency.p50,
      ]),
      status: panel.counter('Status Codes').addTarget($.targets.grpc.status),
    },
    kafka: {
      consume: panel.counter('Consumed').addTarget($.targets.kafka.consume),
      lagP99: panel.timeLog2('Consumer Lag P99').addTarget($.targets.kafka.lag.p99),
      lagP50: panel.timeLog2('Consumer Lag P50').addTarget($.targets.kafka.lag.p50),
      durationP99: panel.timeLog2('Consuming Duration P99').addTarget($.targets.kafka.duration.p99),
      produce: panel.counter('Produced').addTarget($.targets.kafka.produce),
      errors: panel.counter('Producer Errors').addTarget($.targets.kafka.errors),
      repartition: panel.counter('Repartitioned Messages').addTarget($.targets.kafka.repartition),
    },
    postgres: {
      connections: panel.new('Connections').addTargets([
        prom.withAlias($.targets.postgres.connections.open.sum, 'open'),
        prom.withAlias($.targets.postgres.connections.idle.sum, 'idle'),
        prom.withAlias($.targets.postgres.connections.active.sum, 'active'),
      ]),
      latency: panel.timeLinear('Latency', format='ms').addTarget($.targets.postgres.latency.p99),
      calls: panel.counter('Calls').addTarget($.targets.postgres.calls),
      errors: panel.counter('Write Errors').addTarget($.targets.postgres.errors),
    },
  },
  rows: {
    service: row.new('Service Overview').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.service.cpu,
        $.panels.service.goroutines,
        $.panels.service.mem,
        $.panels.service.log,
      ]
    ]),
    http: row.new('HTTP').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.http.latency,
        $.panels.http.status,
      ]
    ]),
    grpc: row.new('gRPC').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.grpc.latency,
        $.panels.grpc.status,
      ]
    ]),
    kafka: row.new('Kafka').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.kafka.consume,
        $.panels.kafka.produce,
        $.panels.kafka.lagP99,
        $.panels.kafka.lagP50,
        $.panels.kafka.durationP99,
        $.panels.kafka.errors,
        $.panels.kafka.repartition,
      ]
    ]),
    postgres: row.new('Postgres').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.postgres.latency,
        $.panels.postgres.calls,
        $.panels.postgres.connections,
        $.panels.postgres.errors,
      ]
    ]),
  },
}
