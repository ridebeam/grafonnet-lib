local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local gcp = import '../helper/gcp.libsonnet';

{
  init(projectName='vehicles-283509')::
    local helpers = gcp.init(projectName);
    local target = helpers.target;
    local panel = helpers.panel;
    local m = target.customMetric;
    local l = target.label;

    local s = {
      targets: {
        process: {
          cpu: target.counter(
            alias='CPU usage',
            metric='kubernetes.io/container/cpu/core_usage_time',
            unit='s',
            valueType='DOUBLE',
          ),
          mem: target.gauges(
            'kubernetes.io/container/memory/used_bytes',
            filters=target.equalsFilter(l('memory_type'), 'non-evictable'),
          ),
          log: target.target(
            metric='logging.googleapis.com/log_entry_count',
            metricKind='DELTA',
            reducer='REDUCE_SUM',
            aligner='ALIGN_RATE',
            groupBys=['metric.label.severity'],
            valueType='INT64',
          ),
        },
        golang: {
          goroutines: target.gauges(m('process/cpu_goroutines')),
        },
        http: {
          latency: target.timers(m('opencensus.io/http/server/latency')),
          status: target.counter(
            metric=m('opencensus.io/http/server/response_count_by_status_code'),
            groupBys=[l('http_status')],
          ),
        },
        grpc: {
          latency: target.timers(m('grpc.io/server/server_latency'), unit='ms'),
          status: target.counter(
            metric=m('grpc.io/server/completed_rpcs'),
            groupBys=[l('grpc_server_status')],
          ),
        },
        kafka: {
          consume: target.counter(
            metric=m('kafka-consume'),
            groupBys=[l('kafka_source_topic')],
          ),
          duration: target.timers(
            metric=m('kafka-consume-duration'),
            groupBys=[l('kafka_source_topic')],
          ),
          lag: target.timers(
            metric=m('kafka-consume-lag'),
            groupBys=[l('kafka_source_topic')],
          ),
          produce: target.counter(
            metric=m('kafka-produce'),
            groupBys=[l('kafka_target_topic')],
          ),
          errors: target.counter(
            metric=m('kafka-produce-error'),
            groupBys=[l('kafka_target_topic')],
          ),
          repartition: target.counter(
            metric=m('kafka-consume-repartition'),
            groupBys=[l('kafka_source_topic')],
          ),
        },
        postgres: {
          connections: {
            open: target.gauges(m('go.sql/db/connections/open')),
            idle: target.gauges(m('go.sql/db/connections/idle')),
            active: target.gauges(m('go.sql/db/connections/active')),
          },
          latency: target.timers(
            metric=m('go.sql/client/latency'),
            groupBys=[l('go_sql_method')],
          ),
          calls: target.counter(
            metric=m('go.sql/client/calls'),
            groupBys=[l('go_sql_method')],
          ),
          errors: target.counter(m('pg-put-error')),
        },
      },
      panels: {
        service: {
          cpu: panel.timeLinear('CPU Usage', legend_show=false).addTarget(s.targets.process.cpu),
          mem: panel.new('Memory Usage', 'bytes', false).addTarget(s.targets.process.mem.sum),
          goroutines: panel.new('Go Routines').addTargets([
            s.targets.golang.goroutines.avg,
            s.targets.golang.goroutines.max,
          ]),
          log: panel.new('Log Output').addTarget(s.targets.process.log)
               .addLink({
            title: 'Logs Explorer',
            url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}%22%0Alabels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22${service}%22?project=vehicles-283509',
            targetBlank: true,
          })
               { options: {
            dataLinks: [{
              title: 'Logs Explorer for ${__series.name}',
              url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.namespace_name%3D%22${env}%22%0Alabels.k8s-pod%2Fapp_kubernetes_io%2Fcomponent%3D%22${service}%22%0Aseverity%3D${__series.name}?project=vehicles-283509',
              targetBlank: true,
            }],
          } },
        },
        http: {
          latency: panel.timeLinear('Latency', format='ms').addTargets([
            s.targets.http.latency.p99,
            s.targets.http.latency.p50,
            s.targets.http.latency.avg,
          ]),
          status: panel.counter('Status Codes').addTarget(s.targets.http.status),
        },
        grpc: {
          latency: panel.timeLinear('Latency', format='ms').addTargets([
            s.targets.grpc.latency.p99,
            s.targets.grpc.latency.p50,
            s.targets.grpc.latency.avg,
          ]),
          status: panel.counter('Status Codes').addTarget(s.targets.grpc.status),
        },
        kafka: {
          consume: panel.counter('Consumed').addTarget(s.targets.kafka.consume),
          lagP99: panel.timeLog2('Consumer Lag P99').addTarget(s.targets.kafka.lag.p99),
          lagP50: panel.timeLog2('Consumer Lag P50').addTarget(s.targets.kafka.lag.p50),
          lagAvg: panel.timeLog2('Consumer Lag AVG').addTarget(s.targets.kafka.lag.avg),
          durationP99: panel.timeLog2('Consuming Duration P99').addTarget(s.targets.kafka.duration.p99),
          produce: panel.counter('Produced').addTarget(s.targets.kafka.produce),
          errors: panel.counter('Producer Errors').addTarget(s.targets.kafka.errors),
          repartition: panel.counter('Repartitioned Messages').addTarget(s.targets.kafka.repartition),
        },
        postgres: {
          connections: panel.new('Connections').addTargets([
            s.targets.postgres.connections.open.sum.withAlias('open'),

            //        target.alias(s.targets.postgres.connections.idle.sum, 'idle'),
            //        target.alias(s.targets.postgres.connections.active.sum, 'active'),
          ]),
          latency: panel.timeLinear('Latency', format='ms').addTarget(s.targets.postgres.latency.p99),
          calls: panel.counter('Calls').addTarget(s.targets.postgres.calls),
          errors: panel.counter('Write Errors').addTarget(s.targets.postgres.errors),
        },
      },
      rows: {
        service: row.new('Service Overview').addPanels([
          panel.halfRow(p)
          for p in [
            s.panels.service.cpu,
            s.panels.service.goroutines,
            s.panels.service.mem,
            s.panels.service.log,
          ]
        ]),
        http: row.new('HTTP').addPanels([
          panel.halfRow(p)
          for p in [
            s.panels.http.latency,
            s.panels.http.status,
          ]
        ]),
        grpc: row.new('gRPC').addPanels([
          panel.halfRow(p)
          for p in [
            s.panels.grpc.latency,
            s.panels.grpc.status,
          ]
        ]),
        kafka: row.new('Kafka').addPanels([
          panel.halfRow(p)
          for p in [
            s.panels.kafka.consume,
            s.panels.kafka.produce,
            s.panels.kafka.lagP99,
            s.panels.kafka.lagP50,
            s.panels.kafka.lagAvg,
            s.panels.kafka.durationP99,
            s.panels.kafka.errors,
            s.panels.kafka.repartition,
          ]
        ]),
        postgres: row.new('Postgres').addPanels([
          panel.halfRow(p)
          for p in [
            s.panels.postgres.latency,
            s.panels.postgres.calls,
            s.panels.postgres.connections,
            s.panels.postgres.errors,
          ]
        ]),
      },
    };

    s,
}
