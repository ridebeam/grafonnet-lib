local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  general: {
    number_of_tables: target.gauges(metric='ClickHouseAsyncMetrics_NumberOfTables').max,
    number_of_databases: target.gauges(metric='ClickHouseAsyncMetrics_NumberOfDatabases').max,
    processes_running: target.gauges(metric='ClickHouseAsyncMetrics_OSProcessesRunning').max,
    processes_blocked: target.gauges(metric='ClickHouseAsyncMetrics_OSProcessesBlocked').max,
    load_average1: target.gauges(metric='ClickHouseAsyncMetrics_LoadAverage1').avg,
    load_average5: target.gauges(metric='ClickHouseAsyncMetrics_LoadAverage5').avg,
    load_average15: target.gauges(metric='ClickHouseAsyncMetrics_LoadAverage15').avg,
  },
  network: {
    receive_bytes: target.gauges(metric='ClickHouseAsyncMetrics_NetworkReceiveBytes_eth0').sum,
    send_bytes: target.gauges(metric='ClickHouseAsyncMetrics_NetworkSendBytes_eth0').sum,
    receive_packets: target.gauges(metric='ClickHouseAsyncMetrics_NetworkReceivePackets_eth0').sum,
    send_packets: target.gauges(metric='ClickHouseAsyncMetrics_NetworkSendPackets_eth0').sum,
    receive_errors: target.gauges(metric='ClickHouseAsyncMetrics_NetworkReceiveErrors_eth0').sum,
    send_errors: target.gauges(metric='ClickHouseAsyncMetrics_NetworkSendErrors_eth0').sum,
  },
  connections: {
    http_threads: target.gauges(metric='ClickHouseAsyncMetrics_HTTPThreads').max,
    tcp_threads: target.gauges(metric='ClickHouseAsyncMetrics_TCPThreads').max,
  },
  disk: {
    total: target.gauges(metric='ClickHouseAsyncMetrics_DiskTotal_default').sum,
    available: target.gauges(metric='ClickHouseAsyncMetrics_DiskAvailable_default').sum,
    used: target.gauges(metric='ClickHouseAsyncMetrics_DiskUsed_default').sum,
  },
};

local panels = {
  general: {
    number_of_tables: panel.new('Number of Tables').addTargets([targets.general.number_of_tables]),
    number_of_databases: panel.new('Number of Databases').addTargets([targets.general.number_of_databases]),
    processes_running: panel.new('Processes Running').addTargets([targets.general.processes_running]),
    processes_blocked: panel.new('Processes Blocked').addTargets([targets.general.processes_blocked]),
    load_average1: panel.new('Load Average 1 min').addTargets([targets.general.load_average1]),
    load_average5: panel.new('Load Average 5 min').addTargets([targets.general.load_average5]),
    load_average15: panel.new('Load Average 15 min').addTargets([targets.general.load_average15]),
  },
  network: {
    receive_bytes: panel.new('Receive Bytes', format='bytes').addTargets([targets.network.receive_bytes]),
    send_bytes: panel.new('Send Bytes', format='bytes').addTargets([targets.network.send_bytes]),
    receive_packets: panel.new('Receive Packets').addTargets([targets.network.receive_packets]),
    send_packets: panel.new('Send Packets').addTargets([targets.network.send_packets]),
    receive_errors: panel.new('Receive Errors').addTargets([targets.network.receive_errors]),
    send_errors: panel.new('Send Errors').addTargets([targets.network.send_errors]),
  },
  connections: {
    http_threads: panel.new('HTTP Threads').addTargets([targets.connections.http_threads]),
    tcp_threads: panel.new('TCP Threads').addTargets([targets.connections.tcp_threads]),
  },
  disk: {
    total: panel.new('Disk Total', format='bytes').addTargets([targets.disk.total]),
    available: panel.new('Disk Available', format='bytes').addTargets([targets.disk.available]),
    used: panel.new('Disk Used', format='bytes').addTargets([targets.disk.used]),
  },
};

local rows = {
  general: row.new('General').addPanels([
    panel.halfRow(p)
    for p in [
      panels.general.number_of_tables,
      panels.general.number_of_databases,
      panels.general.processes_running,
      panels.general.processes_blocked,
      panels.general.load_average1,
      panels.general.load_average5,
      panels.general.load_average15,
    ]
  ]),
  network: row.new('Network').addPanels([
    panel.halfRow(p)
    for p in [
      panels.network.receive_bytes,
      panels.network.send_bytes,
      panels.network.receive_packets,
      panels.network.send_packets,
      panels.network.receive_errors,
      panels.network.send_errors,
    ]
  ]),
  connections: row.new('Connections').addPanels([
    panel.halfRow(p)
    for p in [
      panels.connections.http_threads,
      panels.connections.tcp_threads,
    ]
  ]),
  disk: row.new('Disk').addPanels([
    panel.halfRow(p)
    for p in [
      panels.disk.total,
      panels.disk.available,
      panels.disk.used,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Clickhouse Monitoring',
  uid='clickhouse_monitoring',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true
)

.addTemplate(
  template.custom(
    name='env',
    query='staging,production',
    current='production',
  )
)

.addTemplate(
  template.custom(
    name='service',
    query='clickhouse',
    current='clickhouse',
    hide='variable',
  )
)

.addRows([
  rows.general,
  rows.network,
  rows.connections,
  rows.disk,
])
