local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local libProm = grafana.prometheus;
local prom = import '../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

{
  targets: {
    process: {
      cpu: target.counter(
        metric='container_cpu_usage_seconds_total',
        filters=target.combineFilters(target.equalsFilter('namespace', '$env'), target.equalsFilter('container', '$service')),
        withServiceFilters=false,
        intervalFactor=2,
      ),
      cpuReserved: libProm.target(
        'sum(container_spec_cpu_shares{namespace="$env", container="$service"}[$__interval]) / 1024',
        legendFormat='reserved',
      ),
      cpuEach: target.counter(
        metric='container_cpu_usage_seconds_total',
        filters=target.combineFilters(target.equalsFilter('namespace', '$env'), target.equalsFilter('container', '$service')),
        groupBys=['pod'],
        withServiceFilters=false,
        intervalFactor=2,
      ),
      cpuReservedEach: libProm.target(
        'min(container_spec_cpu_shares{namespace="$env", container="$service"}[$__interval]) / 1024',
        legendFormat='reserved',
      ),
      cpuLimitEach: libProm.target(
        'min(container_spec_cpu_quota{namespace="$env", container="$service"}[$__interval]) / min(container_spec_cpu_period{namespace="$env", container="$service"}[$__interval])',
        legendFormat='limit',
      ),
      cpuThrottled: libProm.target(
        'sum(rate(container_cpu_cfs_throttled_seconds_total{namespace="$env", container="$service"})) / sum(rate(container_cpu_cfs_periods_total{namespace="$env", container="$service"}))',
        legendFormat='throttled',
        intervalFactor=2,
      ),
      mem: target.gauges(
        metric='container_memory_usage_bytes',
        filters=target.combineFilters(target.equalsFilter('namespace', '$env'), target.equalsFilter('container', '$service')),
        withServiceFilters=false,
        intervalFactor=2,
      ),
      memEach: target.gauges(
        metric='container_memory_usage_bytes',
        filters=target.combineFilters(target.equalsFilter('namespace', '$env'), target.equalsFilter('container', '$service')),
        groupBys=['pod'],
        withServiceFilters=false,
        intervalFactor=2,
      ),
      memLimit: target.gauge(
        metric='container_spec_memory_limit_bytes',
        gaugeFunc=target.gaugeFuncs.min,
        alias='limit',
        filters=target.combineFilters(target.equalsFilter('namespace', '$env'), target.equalsFilter('container', '$service')),
        withServiceFilters=false,
      ),
      log: libProm.target(
        // only an approximiation, as we can't get the individual data points, and it is stored as delta, instead of counter
        'sum(avg_over_time(stackdriver_k_8_s_container_logging_googleapis_com_log_entry_count{container_name="$service", namespace_name="$env"}[$__interval])) by (severity, project_id) > 0',
        legendFormat='{{severity}}',
      ),
    },
    golang: {
      goroutines: target.gauges('process/cpu_goroutines'),
      goroutinesEach: target.gauges(
        metric='process/cpu_goroutines',
        groupBys=['pod_name'],
      ),
    },
    http: {
      latency: target.timers('opencensus.io/http/server/latency'),
      status: target.counter(
        metric='opencensus.io/http/server/response_count_by_status_code',
        groupBys=['http_status'],
      ),
    },
    grpc: {
      latency: target.timers('grpc.io/server/server_latency'),
      latencyPerMethod: target.timers(
        metric='grpc.io/server/server_latency',
        filters=target.likeFilter('grpc_server_method', '$grpc_server_method'),
      ),
      status: target.counter(
        metric='grpc.io/server/completed_rpcs',
        groupBys=['grpc_server_status'],
      ),
      statusPerMethod: target.counter(
        metric='grpc.io/server/completed_rpcs',
        groupBys=['grpc_server_status'],
        filters=target.likeFilter('grpc_server_method', '$grpc_server_method'),
      ),
    },
    kafka: {
      consume: target.counter(
        metric='kafka-consume',
        groupBys=['kafka_source_topic'],
      ),
      duration: target.timers(
        metric='kafka-consume-duration',
        groupBys=['kafka_source_topic'],
      ),
      lag: target.timers(
        metric='kafka-consume-lag',
        groupBys=['kafka_source_topic'],
      ),
      produce: target.counter(
        metric='kafka-produce',
        groupBys=['kafka_target_topic'],
      ),
      errors: target.counter(
        metric='kafka-produce-error',
        groupBys=['kafka_target_topic'],
      ),
      repartition: target.counter(
        metric='kafka-consume-repartition',
        groupBys=['kafka_source_topic'],
      ),
    },
    kafkaTopicPerPod: {
      consume: target.counter(
        metric='kafka-consume',
        groupBys=['pod_name'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      duration: target.timers(
        metric='kafka-consume-duration',
        groupBys=['pod_name'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      lag: target.timers(
        metric='kafka-consume-lag',
        groupBys=['pod_name'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      produce: target.counter(
        metric='kafka-produce',
        groupBys=['pod_name'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      errors: target.counter(
        metric='kafka-produce-error',
        groupBys=['pod_name'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      repartition: target.counter(
        metric='kafka-consume-repartition',
        groupBys=['pod_name'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
    },
    kafkaTopicPerPartition: {
      consume: target.counter(
        metric='kafka-consume',
        groupBys=['kafka_source_partition'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      duration: target.timers(
        metric='kafka-consume-duration',
        groupBys=['kafka_source_partition'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      lag: target.timers(
        metric='kafka-consume-lag',
        groupBys=['kafka_source_partition'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      produce: target.counter(
        metric='kafka-produce',
        groupBys=['kafka_source_partition'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      errors: target.counter(
        metric='kafka-produce-error',
        groupBys=['kafka_source_partition'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
      repartition: target.counter(
        metric='kafka-consume-repartition',
        groupBys=['kafka_source_partition'],
        filters=target.equalsFilter('kafka_source_topic', '$kafka_source_topic'),
      ),
    },
    postgres: {
      connections: {
        open: target.gauges('go.sql/db/connections/open'),
        idle: target.gauges('go.sql/db/connections/idle'),
        active: target.gauges('go.sql/db/connections/active'),
      },
      latency: target.timers(
        metric='go.sql/client/latency',
        groupBys=['go_sql_method'],
      ),
      calls: target.counter(
        metric='go.sql/client/calls',
        groupBys=['go_sql_method'],
      ),
      errors: target.counter('pg-put-error').withAlias('pg-put-error'),
    },
  },
  panels: {
    service: {
      cpu: panel.timeLinear('CPU Usage Total', legend_show=true).addTargets([
        $.targets.process.cpu,
        $.targets.process.cpuReserved,
      ]).addSeriesOverride({
        alias: 'reserved',
        fill: 0,
        linewidth: 2,
        color: '#56A64B',
      }),
      cpuEach: panel.timeLinear('CPU Usage Each', legend_show=true).addTargets([
        $.targets.process.cpuEach,
        $.targets.process.cpuReservedEach,
        $.targets.process.cpuLimitEach,
      ]).addSeriesOverride({
        alias: 'limit',
        fill: 0,
        linewidth: 2,
        color: '#C4162A',
      }).addSeriesOverride({
        alias: 'reserved',
        fill: 0,
        linewidth: 2,
        color: '#56A64B',
      }),
      cpuThrottled: panel.timeLinear('CPU Throttled Total', format='percentunit', legend_show=true).addTargets([
        $.targets.process.cpuThrottled,
      ]),
      mem: panel.new('Memory Usage Total', format='bytes', legend_show=false).addTarget($.targets.process.mem.sum),
      memEach: panel.new('Memory Usage Each', format='bytes', legend_show=true).addTargets([
        $.targets.process.memEach.max,
        $.targets.process.memLimit,
      ]).addSeriesOverride({
        alias: 'limit',
        fill: 0,
        linewidth: 2,
        color: '#C4162A',
      }),
      goroutines: panel.new('Go Routines').addTargets([
        $.targets.golang.goroutines.avg,
        $.targets.golang.goroutines.max,
      ]),
      log: panel.new('Log Output (aprox entries per minute)').addTarget($.targets.process.log) {
        options: {
          dataLinks: [
            {
              title: 'Logs Explorer for ${service}',
              url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}﻿%22%0A%28labels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22﻿${service}﻿%22%20OR%20labels.k8s-pod%2Fapp_kubernetes_io%2Fname%3D%22﻿${service}﻿%22%29?project=﻿${__field.labels.project_id}',
              targetBlank: true,
            },
            {
              title: 'Logs Explorer for ${__series.name}',
              url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}﻿%22%0A%28labels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22﻿${service}﻿%22%20OR%20labels.k8s-pod%2Fapp_kubernetes_io%2Fname%3D%22﻿${service}﻿%22%29﻿%0Aseverity%3D﻿${__series.name}?project=﻿${__field.labels.project_id}',
              targetBlank: true,
            },
            {
              title: 'Logs Explorer for ${service} for current time range',
              url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}﻿%22%0A%28labels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22﻿${service}﻿%22%20OR%20labels.k8s-pod%2Fapp_kubernetes_io%2Fname%3D%22﻿${service}﻿%22%29;timeRange=${__from:date}%2F${__to:date}﻿?project=﻿${__field.labels.project_id}',
              targetBlank: true,
            },
            {
              title: 'Logs Explorer for ${__series.name} for current time range',
              url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}﻿%22%0A%28labels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22﻿${service}﻿%22%20OR%20labels.k8s-pod%2Fapp_kubernetes_io%2Fname%3D%22﻿${service}﻿%22%29%0Aseverity%3D﻿${__series.name};timeRange=${__from:date}%2F${__to:date}﻿?project=﻿${__field.labels.project_id}',
              targetBlank: true,
            },
          ],
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
      latencyPerMethod: panel.timeLinear('Latency', format='ms').addTargets([
        $.targets.grpc.latencyPerMethod.p99,
        $.targets.grpc.latencyPerMethod.p50,
      ]),
      status: panel.counter('Status Codes').addTarget($.targets.grpc.status),
      statusPerMethod: panel.counter('Status Codes').addTarget($.targets.grpc.statusPerMethod),
    },
    kafka: {
      consume: panel.counter('Consumed').addTarget($.targets.kafka.consume),
      lagP99: panel.timeLog2('Consumer Lag P99').addTarget($.targets.kafka.lag.p99),
      lagP50: panel.timeLog2('Consumer Lag P50').addTarget($.targets.kafka.lag.p50),
      durationP99: panel.timeLinear('Consuming Duration P99').addTarget($.targets.kafka.duration.p99),
      produce: panel.counter('Produced').addTarget($.targets.kafka.produce),
      errors: panel.counter('Producer Errors').addTarget($.targets.kafka.errors),
      repartition: panel.counter('Repartitioned Messages').addTarget($.targets.kafka.repartition),
    },
    kafkaTopicPerPod: {
      consume: panel.counter('Consumed ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPod.consume),
      lagP99: panel.timeLog2('Consumer Lag P99 ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPod.lag.p99),
      lagP50: panel.timeLog2('Consumer Lag P50 ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPod.lag.p50),
      durationP99: panel.timeLinear('Consuming Duration P99 ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPod.duration.p99),
      produce: panel.counter('Produced ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPod.produce),
      errors: panel.counter('Producer Errors ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPod.errors),
      repartition: panel.counter('Repartitioned Messages ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPod.repartition),
    },
    kafkaTopicPerPartition: {
      consume: panel.counter('Consumed ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPartition.consume),
      lagP99: panel.timeLog2('Consumer Lag P99 ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPartition.lag.p99),
      lagP50: panel.timeLog2('Consumer Lag P50 ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPartition.lag.p50),
      durationP99: panel.timeLinear('Consuming Duration P99 ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPartition.duration.p99),
      produce: panel.counter('Produced ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPartition.produce),
      errors: panel.counter('Producer Errors ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPartition.errors),
      repartition: panel.counter('Repartitioned Messages ${kafka_source_topic}').addTarget($.targets.kafkaTopicPerPartition.repartition),
    },
    postgres: {
      connections: panel.new('Connections').addTargets([
        $.targets.postgres.connections.open.sum.withAlias('open'),
        $.targets.postgres.connections.idle.sum.withAlias('idle'),
        $.targets.postgres.connections.active.sum.withAlias('active'),
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
        $.panels.service.mem,
        $.panels.service.cpuEach,
        $.panels.service.memEach,
        $.panels.service.cpuThrottled,
        $.panels.service.goroutines,
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
    grpcPerMethod: row.new('gRPC ${grpc_server_method}', repeat='grpc_server_method').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.grpc.latencyPerMethod,
        $.panels.grpc.statusPerMethod,
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
    kafkaTopicPerPod: row.new('Kafka per pod ${kafka_source_topic}', repeat='kafka_source_topic').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.kafkaTopicPerPod.consume,
        $.panels.kafkaTopicPerPod.produce,
        $.panels.kafkaTopicPerPod.lagP99,
        $.panels.kafkaTopicPerPod.lagP50,
        $.panels.kafkaTopicPerPod.durationP99,
        $.panels.kafkaTopicPerPod.errors,
        $.panels.kafkaTopicPerPod.repartition,
      ]
    ]),
    kafkaTopicPerPartition: row.new('Kafka per partition ${kafka_source_topic}', repeat='kafka_source_topic').addPanels([
      panel.halfRow(p)
      for p in [
        $.panels.kafkaTopicPerPartition.consume,
        $.panels.kafkaTopicPerPartition.produce,
        $.panels.kafkaTopicPerPartition.lagP99,
        $.panels.kafkaTopicPerPartition.lagP50,
        $.panels.kafkaTopicPerPartition.durationP99,
        $.panels.kafkaTopicPerPartition.errors,
        $.panels.kafkaTopicPerPartition.repartition,
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
