local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';

local cw = import '../../helper/cloudwatch.libsonnet';
local cwHelpers = cw.init();
local panel = cwHelpers.panel;

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'External Data API Overview',
  uid='external-data-api',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  row.new('Service Overview').addPanels([
    panel.halfRow(p)
    for p in [
      panel.new('Average 2XX', legend_show=true).addTarget(
        cloudwatch.target(
          region='ap-southeast-1',
          namespace='AWS/ElasticBeanstalk',
          metric='ApplicationRequests2xx',
          statistic='Average',
          dimensions={ EnvironmentName: 'external-data-api-production' },
          period='auto',
        )
      ),
      panel.new('Average 5XX ', legend_show=true).addTarget(
        cloudwatch.target(
          region='ap-southeast-1',
          namespace='AWS/ElasticBeanstalk',
          metric='ApplicationRequests5xx',
          statistic='Average',
          dimensions={ EnvironmentName: 'external-data-api-production' },
          period='auto',
        )
      ),
      panel.new('Average P90 Latency', legend_show=true).addTarget(
        cloudwatch.target(
          region='ap-southeast-1',
          namespace='AWS/ElasticBeanstalk',
          metric='ApplicationLatencyP90',
          statistic='Average',
          dimensions={ EnvironmentName: 'external-data-api-production' },
          period='auto',
        )
      ),
    ]
  ]),
])
