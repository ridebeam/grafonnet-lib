local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local googleCloudMonitoring = grafana.googleCloudMonitoring;
local template = grafana.template;
local alertCondition = grafana.alertCondition;


// Make sure uid matches the name of the file
grafana.dashboard.new('GCP Service Metrics', uid='gcp-service-metrics')
  .addTemplate(  
    template.custom(
      query='dev,staging,production',
      current='production',
      name='env',
    )
  )

  .addTemplate(  
    template.custom(
      query='iot-server,vehicle-controller',
      current='iot-server',
      name='service',
    )
  )

  // Example of getting metrics from Stackdriver

  .addRow(
    row.new(
      title='Overview'
    )
    .addPanel(
    graphPanel.new(
      'container cpu',
      datasource='Stackdriver',
      span=6,
    )
      .addTarget(
        googleCloudMonitoring.target(
          aliasBy='CPU usage',
          crossSeriesReducer='REDUCE_SUM',
          metricKind='CUMULATIVE',
          perSeriesAligner='ALIGN_DELTA',
          projectName='vehicles-283509',
          metricType='kubernetes.io/container/cpu/core_usage_time',
          filters=[
            "metadata.user_labels.\"app.kubernetes.io/component\"",
            "=",
            "$service",
            "AND",
            "resource.label.namespace_name",
            "=",
            "$env"
          ],
          unit='s',
          valueType='DOUBLE'
        )
      )
    )

    // Panel with multiple metrics
    .addPanel(
    graphPanel.new(
      'Go routines',
      datasource='Stackdriver',
      span=6
    )
      .addTarget(
        googleCloudMonitoring.target(
          projectName='vehicles-283509',
          aliasBy='mean',
          crossSeriesReducer='REDUCE_MEAN',
          perSeriesAligner='ALIGN_MEAN',
          filters=[
            "metric.label.service",
            "=",
            "$service",
            "AND",
            "metric.label.env",
            "=",
            "$env"
          ],
          metricKind='GAUGE',
          metricType='custom.googleapis.com/opencensus/process/cpu_goroutines',
          unit='1',
          valueType='INT64'
        )
      )
      .addTarget(
        googleCloudMonitoring.target(
          projectName='vehicles-283509',
          aliasBy='99th',
          crossSeriesReducer='REDUCE_PERCENTILE_99',
          perSeriesAligner='ALIGN_MAX',
          filters=[
            "metric.label.service",
            "=",
            "$service",
            "AND",
            "metric.label.env",
            "=",
            "$env"
          ],
          metricKind='GAUGE',
          metricType='custom.googleapis.com/opencensus/process/cpu_goroutines',
          unit='1',
          valueType='INT64'
        )
      )
    )
  )


  // Example with getting metrics from Cloudwatch
  .addRow(
    row.new(title='Kafka')
    .addPanel(
    graphPanel.new(
      'kafka lag',
      datasource='CloudWatch',
    )
    .addTarget(
      cloudwatch.target(
        metric='beam_api_Production_kafka_consume_lag',
        namespace='BeamAPI',
        region='ap-southeast-1'
      )
    ), gridPos={
        x: 0,
        y: 0,
        w: 12,
        h: 12,
      }
    )
    
    .addPanel(
    graphPanel.new(
      'kafka lag',
      datasource='Stackdriver',
      span=6,
    )
      .addTarget(
        googleCloudMonitoring.target(
          aliasBy='kafka consume lag iot server',
          crossSeriesReducer='REDUCE_PERCENTILE_99',
          metricKind='CUMULATIVE',
          perSeriesAligner='ALIGN_DELTA',
          projectName='vehicles-283509',
          metricType='custom.googleapis.com/opencensus/kafka-consume-lag',
          filters=[
            "metric.label.env","=","production","AND","metric.label.service","=","iot-server"
          ],
          groupBys=["metric.label.kafka_source_topic"],
          unit='s',
          valueType='DISTRIBUTION'
        )
      )
    )
  )
