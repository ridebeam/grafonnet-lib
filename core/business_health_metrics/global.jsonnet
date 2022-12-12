local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local jwebb = import '../../helper/jwebb.libsonnet';

// Add metrics here
local metrics = [
  {
    name: 'trips',
    title: 'Trip Starts',
    query: 'select 1 as city_id, time_bucket, count from jwebb.trips_count_global where $timeFilter order by time_bucket asc',
  },
];

local rows = [
  row.new(metric.title).addPanels([jwebb.newPanel(metric, '1', coverage=0.9999)])
  for metric in metrics
];

grafana.dashboard.new(
  'Global Metrics',
  uid='global',
  refresh='15m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now+2d',
  tags=['generated'],
  editable=true,
)

.addRows(rows) {
  annotations: {
    list: [
      {
        builtIn: 1,
        datasource: {
          type: 'grafana',
          uid: '-- Grafana --',
        },
        enable: true,
        hide: true,
        iconColor: 'red',
        name: 'Annotations & Alerts',
        target: {
          limit: 100,
          matchAny: false,
          tags: [
            'alert',
            'metric:trips',
            'type:global',
          ],
          type: 'tags',
        },
        type: 'dashboard',
      },
      {
        datasource: {
          type: 'vertamedia-clickhouse-datasource',
          uid: '_Az-rRXnz',
        },
        enable: true,
        hide: true,
        iconColor: 'blue',
        name: 'Now',
        query: "select toUInt32(toStartOfInterval(now(), INTERVAL 30 minute))*1000 as time, 'Now' as text",
      },
    ],
  },
}
