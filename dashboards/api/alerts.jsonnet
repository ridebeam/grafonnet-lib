local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';

local cloudwatchHelpers = import '../../helper/cloudwatch.libsonnet';
local cwHelpers = cloudwatchHelpers.init();
local cwPanel = cwHelpers.panel;

local gcp = import '../../helper/gcp.libsonnet';
local gcpHelpers = gcp.init();
local gcpTarget = gcpHelpers.target;
local gcpPanel = gcpHelpers.panel;
local m = gcpTarget.customMetric;
local l = gcpTarget.label;

local alertDefaults = {
  format: 'short',
  channels: alerts.notifications.productionAlerts,
  thresholdType: 'gt',
  evaluateFor: '5m',
};

local gcpFilterMessaging = gcpTarget.equalsFilter('resource.label.container_name', 'messaging');

// one entry per row, with a list of panels for each alert (counter/timing)
local alertDefinitions = [
  {
    row: 'Postgres',
    alerts: [
      {
        title: 'CDC Replication Lag (Critical)',
        cloudwatch: { namespace: 'AWS/RDS', name: 'OldestReplicationSlotLag', dimensions: { DBInstanceIdentifier: 'liveescooter' } },
        format: 'bytes',
        threshold: 100000000000,
        message: '',  // TODO message
      },
      {
        title: 'CDC Replication Lag (Warning)',
        cloudwatch: { namespace: 'AWS/RDS', name: 'OldestReplicationSlotLag', dimensions: { DBInstanceIdentifier: 'liveescooter' } },
        format: 'bytes',
        threshold: 10000000000,
        channels: alerts.notifications.productionWarnings,
        message: '',  // TODO message
      },
      {
        title: 'Analytics DB Replication Lag',
        cloudwatch: { namespace: 'AWS/RDS', name: 'ReplicaLag', dimensions: { DBInstanceIdentifier: 'analytics-prod' } },
        format: 's',
        threshold: 29,
        message: '',  // TODO message
      },
      {
        title: 'Production DB CPU Usage (Critical)',
        cloudwatch: { namespace: 'AWS/RDS', name: 'CPUUtilization', dimensions: { DBInstanceIdentifier: 'liveescooter' } },
        format: 'percent',
        threshold: 80,
        message: '',  // TODO message
      },
      {
        title: 'Production DB CPU Usage (Warning)',
        cloudwatch: { namespace: 'AWS/RDS', name: 'CPUUtilization', dimensions: { DBInstanceIdentifier: 'liveescooter' } },
        format: 'percent',
        threshold: 60,
        channels: alerts.notifications.productionWarnings,
        message: '',  // TODO message
      },
      {
        title: 'Production DB Free Disk',
        cloudwatch: { namespace: 'AWS/RDS', name: 'FreeStorageSpace', dimensions: { DBInstanceIdentifier: 'liveescooter' } },
        format: 'bytes',
        threshold: 50000000000,
        thresholdType: 'lt',
        message: '',  // TODO message
      },
      {
        title: 'Production DB Connections',
        cloudwatch: { namespace: 'AWS/RDS', name: 'DatabaseConnections', dimensions: { DBInstanceIdentifier: 'liveescooter' } },
        threshold: 800,
        message: '',  // TODO message
      },
      {
        title: 'Production DB Vehicle Table Bloat',
        gcpGauge: {
          name: m('table-bloat'),
          filters: gcpTarget.equalsFilter(l('table_name'), 'Vehicles'),
        },
        threshold: 50,
        message: |||
          Vehicle table bloat is high
          Run VACUUM FULL "Vehicles";
          https://beammobility.atlassian.net/wiki/spaces/BE/pages/543653889/Database+table+bloat
        |||,
      },
    ],
  },
  {
    row: 'Redis',
    alerts: [
      {
        title: 'Memory Usage (Critical)',
        cloudwatch: { namespace: 'AWS/ElastiCache', name: 'FreeableMemory', dimensions: { CacheClusterId: 'production' } },
        format: 'bytes',
        threshold: 4400000000,
        message: |||
          Production Redis free memory is low, current Redis instance is m5.large, with 4.79GB usable memory.
          Please check about the issue and either:
          1. If there are a new large volume of vehicles registered recently
          2. clean up the leaking memory if it is due to memory leak
          3. upgrade the instance if it is due to data volume
          4. if this is a false alarm, please update the grafana alert config.

          P.S. the max memory available to use can be checked use `INFO` command after connect to Redis
        |||,
      },
      {
        title: 'CPU Usage (Critical)',
        cloudwatch: { namespace: 'AWS/ElastiCache', name: 'CPUUtilization', dimensions: { CacheClusterId: 'production' } },
        format: 'percent',
        threshold: 80,
        message: '',  // TODO message
      },
    ],
  },

  {
    row: 'API',
    alerts: [
      {
        title: 'Rate of HTTP 500s',
        cloudwatch: { namespace: 'AWS/ElasticBeanstalk', name: 'ApplicationRequests5xx', dimensions: { EnvironmentName: 'docker-production' } },
        threshold: 20,
        message: '',  // TODO message
      },
      {
        title: 'HTTP Endpoint Latency P99',
        cloudwatch: { namespace: 'AWS/ElasticBeanstalk', name: 'ApplicationLatencyP99', dimensions: { EnvironmentName: 'docker-production' } },
        format: 's',
        threshold: 10,
        message: '',  // TODO message
      },
      {
        title: 'Health Status - API',
        cloudwatch: { namespace: 'AWS/ElasticBeanstalk', name: 'EnvironmentHealth', dimensions: { EnvironmentName: 'docker-production' } },
        threshold: 20,
        message: '',  // TODO message
      },
      {
        title: 'Health Status - Messaging',
        cloudwatch: { namespace: 'AWS/ElasticBeanstalk', name: 'EnvironmentHealth', dimensions: { EnvironmentName: 'docker-production-messaging' } },
        threshold: 20,
        message: '',  // TODO message
      },
      {
        title: 'Kafka: vehicle-event consumption lag',
        gcpTimer: {
          name: m('kafka-consume-lag'),
          filters: gcpTarget.combineFilters(
            gcpFilterMessaging,
            gcpTarget.equalsFilter(l('kafka_source_topic'), 'vehicle-event'),
          ),
        },
        threshold: 60,
        // TODO message
        message: |||
          TODO
        |||,
      },
      {
        title: 'Kafka: vehicle-event consumption lag',
        gcpTimer: {
          name: m('kafka-consume-lag'),
          filters: gcpTarget.combineFilters(
            gcpFilterMessaging,
            gcpTarget.equalsFilter(l('kafka_source_topic'), 'vehicle-event'),
          ),
        },
        threshold: 60,
        // TODO message
        message: |||
          TODO
        |||,
      },
    ],
  },
  {
    row: 'Redash',
    alerts: [
      {
        title: 'Redash DB Memory Usage',
        cloudwatch: { namespace: 'AWS/RDS', name: 'FreeableMemory', dimensions: { DBInstanceIdentifier: 'redash-db' } },
        format: 'bytes',
        threshold: 15000000000,
        message: |||
          Redash DB MEM Usage is above 1.8GB for more than 3min.

          Redash DB instance memory is 2GB, please check to make sure the current instance is still in healthy load.

          Redash DB: https://ap-southeast-1.console.aws.amazon.com/rds/home?region=ap-southeast-1#database:id=redash-db;is-cluster=false;tab=connectivity
          Database: postgres
          Username and password is in buttercup.

          If the load requires bigger instance, we may want to upgrade it.
        |||,
      },
      {
        title: 'Redash DB CPU Usage',
        cloudwatch: { namespace: 'AWS/RDS', name: 'CPUUtilization', dimensions: { DBInstanceIdentifier: 'redash-db' } },
        format: 'percent',
        threshold: 80,
        evaluteFor: '3m',
        message: |||
          Redash CPU Usage is above 80% for 3min.

          Please check.

          Redash DB: https://ap-southeast-1.console.aws.amazon.com/rds/home?region=ap-southeast-1#database:id=redash-db;is-cluster=false;tab=monitoring
          URL: redash-db.c54omatykt2j.ap-southeast-1.rds.amazonaws.com
          database: postgres
          Username and password is in buttercup.
        |||,
      },
      {
        title: 'Redash DB Free Disk Space',
        cloudwatch: { namespace: 'AWS/RDS', name: 'FreeStorageSpace', dimensions: { DBInstanceIdentifier: 'redash-db' } },
        format: 'bytes',
        threshold: 20 * 1024 * 1024 * 1024,  // 20 GB
        thresholdType: 'lt',
        message: |||
          Redash DB free storage is dropped to lower than 20GB.

          Please check the query_result table to make sure old data is cleared.

          Redash DB: https://ap-southeast-1.console.aws.amazon.com/rds/home?region=ap-southeast-1#database:id=redash-db;is-cluster=false
          Connection URL: redash-db.c54omatykt2j.ap-southeast-1.rds.amazonaws.com
          Database: postgres
          Username and password are in buttercup.
        |||,
      },
      {
        title: 'Redash Disk Space',
        cloudwatch: {
          namespace: 'Redash',
          name: 'disk_used_percent',
          dimensions: {
            InstanceId: 'i-0fdd39ae09662d72f',
            device: '*',
            fstype: '*',
            path: '/',
          },
        },
        format: 'percent',
        threshold: 75,
        message: |||
          Redash Disk Usage is above 75%.

          Please check the disk usage for the Redash server and take action, we may want to upgrade the volume or instance correspondingly based on the usage of the disk.

          Refer to: https://beammobility.atlassian.net/wiki/spaces/BE/pages/513179649/Redash+Setup for connecting to the Redash server.
        |||,
      },
      {
        title: 'Redash CPU Usage',
        cloudwatch: {
          namespace: 'AWS/EC2',
          name: 'CPUUtilization',
          dimensions: {
            InstanceId: 'i-0fdd39ae09662d72f',
          },
        },
        format: 'percent',
        threshold: 75,
        message: |||
          Redash server CPU usage > 75% alert

          Check the Redash EC2 instance status: https://ap-southeast-1.console.aws.amazon.com/ec2/v2/home?region=ap-southeast-1#InstanceDetails:instanceId=i-0fdd39ae09662d72f

          Common issue and solutions: https://beammobility.atlassian.net/wiki/spaces/BE/pages/513179649/Redash+Setup
        |||,
      },
      {
        title: 'Redash Memory Usage',
        cloudwatch: {
          namespace: 'Redash',
          name: 'mem_used_percent',
          dimensions: {
            InstanceId: 'i-0fdd39ae09662d72f',
          },
        },
        format: 'percent',
        threshold: 75,
        message: |||
          Redash memory usage is above 75%.

          Please check the Redash server status and take action correspondingly.

          We may want to upgrade the instance type if there are too many queries/jobs to be processed by the Redash server.

          Refer to: https://beammobility.atlassian.net/wiki/spaces/BE/pages/513179649/Redash+Setup for instructions on how to connect to Redash server.
        |||,
      },
    ],
  },
];

local createGCPCounter(metric) = gcpTarget.counter(
  metric=metric.name,
  filters=gcpTarget.combineFilters(
    metric.filters,
    gcpTarget.equalsFilter('resource.label.namespace_name', 'production'),
  ),
  withServiceFilters=false,
);

local createGCPGauge(metric) = gcpTarget.gauges(
  metric=metric.name,
  filters=gcpTarget.combineFilters(
    metric.filters,
    gcpTarget.equalsFilter('resource.label.namespace_name', 'production'),
  ),
  withServiceFilters=false,
).max;

local createGCPTimer(metric) = gcpTarget.timers(
  metric=metric.name,
  filters=gcpTarget.combineFilters(
    metric.filters,
    gcpTarget.equalsFilter('resource.label.namespace_name', 'production'),
  ),
  withServiceFilters=false,
).p99;

// create a simple counter, with the metric name as alias
local createCloudwatchTarget(metric) = cloudwatch.target(
  region='default',
  namespace=metric.namespace,
  metric=metric.name,
  dimensions=metric.dimensions,
  period='auto',
);

local createTarget(alertDefinition) =
  if 'cloudwatch' in alertDefinition then
    createCloudwatchTarget(alertDefinition.cloudwatch)
  else if 'gcpCounter' in alertDefinition then
    createGCPCounter(alertDefinition.gcpCounter)
  else if 'gcpGauge' in alertDefinition then
    createGCPGauge(alertDefinition.gcpGauge)
  else if 'gcpTimer' in alertDefinition then
    createGCPTimer(alertDefinition.gcpTimer)
  else {};

local panelHelper(alertDefinition) =
  if 'cloudwatch' in alertDefinition then
    cwPanel
  else if 'gcpCounter' in alertDefinition then
    gcpPanel
  else if 'gcpGauge' in alertDefinition then
    gcpPanel
  else if 'gcpTimer' in alertDefinition then
    gcpPanel
  else {};

// create for each entry a counter panel with alert
// TODO move to helper
local createAlert(definition) =
  local def = alertDefaults + definition;
  [
    panelHelper(def).counter(def.title, format=def.format).addTargets([
      createTarget(def),
    ]).addAlert(
      def.title,
      notifications=def.channels,
      message='%s\n\n%s' % [def.title, def.message],
      forDuration=def.evaluateFor,
      frequency='1m',
    ).addConditions([
      alerts.newCondition(reducerType='avg', threshold=def.threshold, thresholdType=def.thresholdType),
    ]),
  ];

// create panels for each row and put two panels side by side
local rows = [
  row.new(r.row).addPanels([
    cwPanel.halfRow(p)
    for p in std.flattenArrays([
      createAlert(alert)
      for alert in r.alerts
    ])
  ])
  for r in alertDefinitions
];

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts',
  uid='api_alerts',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(rows)
