local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local googleCloudMonitoring = grafana.googleCloudMonitoring;
local template = grafana.template;
local alertCondition = grafana.alertCondition;
local k8s = import 'k8s.libsonnet';

// Make sure uid matches the name of the file
grafana.dashboard.new('[Demo] Service Metrics', uid='demo-service-metrics')
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

  // Example with getting metrics from Cloudwatch
  .addRow(
    row.new(title='Cloudwatch')
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
    
  )
