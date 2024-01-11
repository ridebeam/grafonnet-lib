local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local k8s = import '../k8s-promql.libsonnet';
local prom = import '../../helper/promql.libsonnet';
local libProm = grafana.prometheus;

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local createHeapMemoryMetric(areaId) = libProm.target(
    '(
        (sum(avg_over_time(jvm_memory_used_bytes{area="heap", namespace="$env", service="$service", id="' + areaId + '"}[15s])) by (pod_name)) 
        / 
        (sum(avg_over_time(jvm_memory_max_bytes{id="' + areaId + '", area="heap", namespace="$env", service="$service"}[15s])) by (pod_name))
    ) * 100',
    legendFormat='{{pod_name}}',
  );

local targets = {
    serviceStatus: {
        status: libProm.target(
            'up{namespace="$env", service="$service"}',
            legendFormat='{{pod_name}}'
        ),
        uptime: libProm.target(
          'time() - process_start_time_seconds{namespace="$env", service="$service"}',
          legendFormat='{{pod_name}}'
        ),
        startTime: libProm.target(
          'process_start_time_seconds{namespace="$env", service="$service"}*1000',
          legendFormat='{{pod_name}}'
        )
    },
    gc: {
      gcTime: libProm.target(
        'increase(jvm_gc_pause_seconds_sum{namespace="$env", service="$service"}[1m])',
        legendFormat='{{pod_name}}'
      ),
      gcCount: libProm.target(
        'sum(increase(jvm_gc_pause_seconds_count{namespace="$env", service="$service"}[1m]))',
        legendFormat='{{pod_name}}'
      )
    },
    memory: {
      memoryArea: libProm.target(
        'jvm_memory_used_bytes{namespace="$env", service="$service", area=~"heap|nonheap"}',
        legendFormat='Used {{ area }} - {{pod_name}}'
      ),
      survivorSpace: createHeapMemoryMetric('Survivor Space'),
      edenSpace: createHeapMemoryMetric('Eden Space'),
      tenuredGen: createHeapMemoryMetric('Tenured Gen')
    },
};

local panels = {
  serviceStatus: {
    status: panel.new("Status").addTargets([
      targets.serviceStatus.status
    ]) {
        fieldConfig: {
          defaults: {
            mappings: [
              {
                options: {
                  "0": {
                    text: "DOWN"
                  },
                  "1": {
                    text: "UP"
                  }
                },
                type: "value"
              },
              {
                options: {
                  match: "null",
                  result: {
                    text: "DOWN"
                  }
                },
                type: "special"
              }
            ],
          },
        },
        options: {
          textMode: "auto",
          graphMode: "none",
        }
      },
    uptime: panel.new("Uptime").addTargets([
      targets.serviceStatus.uptime
    ]) {
        fieldConfig: {
          defaults: {
            mappings: [
              {
                options: {
                  match: "null",
                  result: {
                    text: "N/A"
                  }
                },
                type: "special"
              }
            ],
            unit: "s"
          },
        },
        options: {
          orientation: "horizontal",
          textMode: "auto",
          colorMode: "none",
          graphMode: "none",
        }
    },
    startTime: panel.new("Start Time").addTargets([
      targets.serviceStatus.startTime
    ]) {
        fieldConfig: {
          defaults: {
            unit: "dateTimeAsIso"
          },
        },
        options: {
          orientation: "horizontal",
          textMode: "auto",
          colorMode: "none",
          graphMode: "none",
        },
    },
  },
  gc: {
    gcTime: panel.new("GC Time").addTargets([
      targets.gc.gcTime
    ]) {
        fieldConfig: {
          defaults: {
            unit: "s"
          },
        }
    },
    gcCount: panel.new("GC Count").addTargets([
      targets.gc.gcCount
    ]) {
        fieldConfig: {
          defaults: {
            unit: "s"
          },
        }
    },
  },
  memory: {
    memoryArea: panel.new("Heap Memory Area").addTargets([
      targets.memory.memoryArea
    ]) {
        fieldConfig: {
          defaults: {
            unit: "bytes"
          },
        }
    },
    survivorSpace: panel.new("Heap - Survivor Space").addTargets([
      targets.memory.survivorSpace
    ]) {
        fieldConfig: {
          defaults: {
            unit: "percent"
          },
        }
    },
    edenSpace: panel.new("Heap - Eden Space").addTargets([
      targets.memory.edenSpace
    ]) {
        fieldConfig: {
          defaults: {
            unit: "percent"
          },
        }
    },
    tenuredGen: panel.new("Heap - Tenured Gen").addTargets([
      targets.memory.tenuredGen
    ]) {
        fieldConfig: {
          defaults: {
            unit: "percent"
          },
        }
    },
  },
};

local rows = {
  service: row.new("Service Status").addPanels([
    panel.thirdRow(p) { type: 'stat' }
    for p in [
      panels.serviceStatus.status,
      panels.serviceStatus.uptime,
      panels.serviceStatus.startTime,
    ]
  ]),
  gc: row.new("Garbage Collector").addPanels([
    panel.halfRow(p)
    for p in [
      panels.gc.gcTime,
      panels.gc.gcCount,
    ]
  ]),
  memory: row.new("Memory").addPanels([
    panel.halfRow(p)
    for p in [
      panels.memory.memoryArea,
      panels.memory.survivorSpace,
      panels.memory.edenSpace,
      panels.memory.tenuredGen,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'JVM Service',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['overview', 'generic', 'generated', 'jvm'],
)
.addTemplate(
  template.custom(
    name='env',
    query='dev,staging,stable,production',
    current='production',
  )
)
.addTemplate(
  template.new(
    name='service',
    datasource=null,
    query='label_values(jvm_memory_used_bytes, service)',
    current='api',
    refresh=1,
    sort=1,
  )
)
.addRows([
  rows.service,
  rows.gc,
  rows.memory,
])
