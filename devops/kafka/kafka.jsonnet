local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local promHelper = import '../../helper/promql.libsonnet';
local prom = grafana.prometheus;

local template = grafana.template;
local helpers = promHelper.init();
local target = helpers.target;
local panel = helpers.panel;
local libProm = grafana.prometheus;
local row = grafana.row;

local thresholds = [
  {
    color: 'green',
    value: null,
  },
  {
    color: 'orange',
    value: 80,
  },
  {
    color: 'red',
    value: 90,
  },
];

local panels = {
  global: {
    writeOnTopics: panel.stat(
      title='Write on topics (rate)',
      description='Per-second average rate of ingress of data to topics, basic/standard cluster has a max of 250MBps.',
      unit='decbytes',
      thresholdsMode='percentage',
      max=250000000,
      reducerFunction='lastNotNull'
    ).addThresholds(thresholds).addTarget(
      target.rate(
        metric='confluent_kafka_server_received_bytes',
        withServiceFilters=false,
        filters='cluster="devops-sg", kafka_id=~"$cluster_id", topic=~"$topic"',
        interval='1m',
      )
    ),

    readOfTopics: panel.stat(
      title='Read of topics (rate)',
      description='Per-second average rate of egress of data from topics, basic/standard cluster has a max of 750MBps.',
      unit='decbytes',
      thresholdsMode='percentage',
      max=750000000,
      reducerFunction='lastNotNull'
    ).addThresholds(thresholds).addTarget(
      target.rate(
        metric='confluent_kafka_server_sent_bytes',
        withServiceFilters=false,
        filters='cluster="devops-sg", kafka_id=~"$cluster_id", topic=~"$topic"',
        interval='1m',
      )
    ),

    requestCount: panel.stat(
      title='Request count (rate)',
      description='Per-second average rate of requests, basic/standard cluster maxes out at 15000 requests per second.',
      thresholdsMode='percentage',
      max=15000,
      reducerFunction='lastNotNull'
    ).addThresholds(thresholds).addTarget(
      target.rate(
        metric='confluent_kafka_server_request_count',
        withServiceFilters=false,
        filters='cluster="devops-sg", kafka_id=~"$cluster_id"',
        interval='1m',
      )
    ),

    retainedByte: panel.stat(
      title='Retained bytes',
      description='Basic clusters have a max retained bytes limit of 5 TB prior to replication. ccloud_metrics_retained_bytes is after replication thus needs to be divided by 3.',
      unit='decbytes',
      thresholdsMode='percentage',
      max=5000000000000,
      reducerFunction='lastNotNull'
    ).addThresholds(thresholds).addTarget(
      prom.target(
        expr='sum(confluent_kafka_server_retained_bytes{cluster="devops-sg", kafka_id=~"$cluster_id", topic=~"$topic"}) / 3',
      )
    ),

    totalClusters: panel.stat(
      title='Total clusters',
      description='Total number of clusters.',
      thresholdsMode='percentage',
      reducerFunction='max',
      unit=null,
      min=null,
    ).addThresholds(thresholds).addTarget(
      prom.target(
        expr='count(confluent_kafka_server_partition_count{cluster="devops-sg"})',
      )
    ),

    totalConnectors: panel.stat(
      title='Total connectors',
      description='Total number of connectors.',
      thresholdsMode='percentage',
      reducerFunction='max',
      unit=null,
      min=null,
    ).addThresholds(thresholds).addTarget(
      prom.target(
        expr='count(confluent_kafka_connect_sent_bytes{cluster="devops-sg"})',
      )
    ),

    avgActiveConnection: panel.stat(
      title='Average active connection',
      description='The average active connections to a cluster. Basic/standard clusters limit active connections to 1000.',
      thresholdsMode='percentage',
      reducerFunction='max',
      max=1000,
    ).addThresholds(thresholds).addTarget(
      prom.target(
        expr='avg(confluent_kafka_server_active_connection_count{cluster="devops-sg", kafka_id=~"$cluster_id"})',
      )
    ),

    partitionCount: panel.stat(
      title='Partition count',
      description='The sum of partitions in a cluster. Basic/standard cluster max partitions limit is 4096.',
      max=4096,
      thresholdsMode='percentage',
    ).addThresholds(thresholds).addTarget(
      prom.target(
        expr='confluent_kafka_server_partition_count{cluster="devops-sg", kafka_id=~"$cluster_id"}',
        legendFormat='{{kafka_id}}',
      )
    ),

    consumerLag: panel.timeseries(
      title='Consumer lag',
      description="The lag between a group member's committed offset and the partition's high watermark.",
      toolTipMode='multi',
      tooltipSort='desc',
      unit=null
    ).addThresholds(thresholds).addTarget(
      prom.target(
        expr='sum by (consumer_group_id, topic) (confluent_kafka_server_consumer_lag_offsets{cluster="devops-sg", topic=~"$topic", kafka_id=~"$cluster_id"})',
        legendFormat='{{topic}}-{{consumer_group_id}}',
      )
    ),

    authenticationRate: panel.timeseries(
      title='Authentication rate',
      description='The delta count of successful authentications. Each sample is the number of successful authentications since the previous data point. The count sampled every 60 seconds.',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addThresholds(thresholds).addTarget(
      prom.target(
        expr='confluent_kafka_server_successful_authentication_count{cluster="devops-sg"}',
        legendFormat='{{principal_id}}',
      )
    ),
  },
  topic: {
    topicRetainBytes: panel.timeseries(
      title='Topic retained bytes',
      description='The current count of bytes retained by the cluster, summed across all partitions. The count is sampled every 60 seconds.',
      unit='decbytes',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='sum by (kafka_id, topic) (confluent_kafka_server_retained_bytes{cluster="devops-sg",topic=~"$topic", kafka_id=~"$cluster_id"})',
        legendFormat='{{kafka_id}}-{{topic}}',
      )
    ),

    topicReceivedBytes: panel.timeseries(
      title='Topic received bytes',
      description='The delta count of bytes received from the network. Each sample is the number of bytes received since the previous data sample. The count is sampled every 60 seconds.',
      unit='decbytes',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='sum by (topic, kafka_id) (confluent_kafka_server_received_bytes{cluster="devops-sg", topic=~"$topic", kafka_id=~"$cluster_id"})',
        legendFormat='{{topic}} - {{kafka_id}}',
      )
    ),

    topicSentBytes: panel.timeseries(
      title='Topic sent bytes',
      description='The delta count of bytes sent over the network. Each sample is the number of bytes sent since the previous data point. The count is sampled every 60 seconds.',
      unit='decbytes',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='sum by (topic, kafka_id) (confluent_kafka_server_sent_bytes{cluster="devops-sg", topic=~"$topic", kafka_id=~"$cluster_id"})',
        legendFormat='{{topic}} - {{kafka_id}}',
      )
    ),

    topicReceivedRecords: panel.timeseries(
      title='Topic received records',
      description='The delta count of records received. Each sample is the number of records received since the previous data sample. The count is sampled every 60 seconds.',
      unit='none',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='sum by (topic, kafka_id) (confluent_kafka_server_received_records{cluster="devops-sg", topic=~"$topic", kafka_id=~"$cluster_id"})',
        legendFormat='{{topic}} - {{kafka_id}}',
      )
    ),

    topicSentRecords: panel.timeseries(
      title='Topic sent records',
      description='The delta count of records sent. Each sample is the number of records sent since the previous data point. The count is sampled every 60 seconds.',
      unit='none',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='sum by (topic, kafka_id) (confluent_kafka_server_sent_records{cluster="devops-sg", topic=~"$topic", kafka_id=~"$cluster_id"})',
        legendFormat='{{topic}} - {{kafka_id}}',
      )
    ),

    requestRate: panel.timeseries(
      title='Request rate',
      description='The delta count of records sent. Each sample is the number of records sent since the previous data point. The count is sampled every 60 seconds.',
      unit='decbytes',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='confluent_kafka_server_request_count{cluster="devops-sg", kafka_id=~"$cluster_id"}',
        legendFormat='{{kafka_id}}-{{type}}',
      )
    ),
  },

  connectors: {
    receiveBytes: panel.timeseries(
      title='Received bytes',
      description='The delta count of total bytes received by the sink connector. Each sample is the number of bytes received since the previous data point. The count is sampled every 60 seconds.',
      unit='decbytes',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='confluent_kafka_connect_received_bytes{cluster="devops-sg", connector_id=~"$connector_id"}',
        legendFormat='{{connector_id}}',
      )
    ),

    sentBytes: panel.timeseries(
      title='Sent bytes',
      description='The delta count of total number of records sent from the transformations and written to Kafka for the source connector. Each sample is the number of records sent since the previous data point. The count is sampled every 60 seconds.',
      unit='decbytes',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='confluent_kafka_connect_sent_bytes{cluster="devops-sg", connector_id=~"$connector_id"}',
        legendFormat='{{connector_id}}',
      )
    ),

    receivedRecords: panel.timeseries(
      title='Received records',
      description='The delta count of total number of records received by the sink connector. Each sample is the number of records received since the previous data point. The count is sampled every 60 seconds.',
      unit=null,
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='confluent_kafka_connect_received_records{cluster="devops-sg", connector_id=~"$connector_id"}',
        legendFormat='{{connector_id}}',
      )
    ),

    sentRecords: panel.timeseries(
      title='Sent records',
      description='The delta count of total number of records sent from the transformations and written to Kafka for the source connector. Each sample is the number of records sent since the previous data point. The count is sampled every 60 seconds.',
      unit=null,
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='confluent_kafka_connect_sent_records{cluster="devops-sg", connector_id=~"$connector_id"}',
        legendFormat='{{connector_id}}',
      )
    ),

    deadLaterQueueBytes: panel.timeseries(
      title='Dead letter queue bytes',
      description='The delta count of dead letter queue records written to Kafka for the sink connector. The count is sampled every 60 seconds.',
      unit='decbytes',
      toolTipMode='multi',
      tooltipSort='desc',
    ).addTarget(
      prom.target(
        expr='confluent_kafka_connect_dead_letter_queue_records{cluster="devops-sg", connector_id=~"$connector_id"}',
        legendFormat='{{connector_id}}',
      )
    ),
  },
};

local rows = {
  global: row.new('Global').addPanels([
    p
    for p in [
      panels.global.totalClusters { span: 3 },
      panels.global.totalConnectors { span: 3 },
      panels.global.retainedByte { span: 3 },
      panels.global.writeOnTopics { span: 3 },
      panels.global.readOfTopics { span: 3 },
      panels.global.requestCount { span: 3 },
      panels.global.avgActiveConnection { span: 3 },
      panels.global.partitionCount { span: 12 },
      panels.global.consumerLag { span: 12 },
      panels.global.authenticationRate { span: 12 },
    ]
  ]),
  topics: row.new('Topics').addPanels([
    p
    for p in [
      panels.topic.topicRetainBytes { span: 12 },
      panels.topic.topicReceivedBytes { span: 6 },
      panels.topic.topicSentBytes { span: 6 },
      panels.topic.topicReceivedRecords { span: 6 },
      panels.topic.topicSentRecords { span: 6 },
      panels.topic.requestRate { span: 12 },
    ]
  ]),
  connectors: row.new('Connectors').addPanels([
    panels.connectors.receiveBytes { span: 6 },
    panels.connectors.sentBytes { span: 6 },
    panels.connectors.receivedRecords { span: 6 },
    panels.connectors.sentRecords { span: 6 },
    panels.connectors.deadLaterQueueBytes { span: 12 },
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Kafka overview',
  uid='kafka_overview',
  refresh='5s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-1h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addTemplate(
  template.new(
    name='cluster_id',
    label='Cluster ID',
    datasource=null,
    query='label_values(confluent_kafka_server_partition_count{cluster="devops-sg"}, kafka_id)',
    allValues='.*',
    current='lkc-5dqp2',
    includeAll=true,
    multi=true,
    refresh=1,
    sort=1,
  )
)
.addTemplate(
  template.new(
    name='topic',
    label='Topic',
    datasource=null,
    query='label_values(confluent_kafka_server_received_bytes{cluster="devops-sg", kafka_id=~"$cluster_id"}, topic)',
    allValues='.*',
    current='All',
    includeAll=true,
    multi=true,
    refresh=1,
    sort=1,
  )
)
.addTemplate(
  template.new(
    name='connector_id',
    label='Connector ID',
    datasource=null,
    query='label_values(confluent_kafka_connect_received_bytes{cluster="devops-sg"}, connector_id)',
    allValues='.*',
    current='All',
    includeAll=true,
    multi=true,
    refresh=1,
    sort=1,
  )
)
.addRows([
  rows.global,
  rows.topics,
  rows.connectors,
])
