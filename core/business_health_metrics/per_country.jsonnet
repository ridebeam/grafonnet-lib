local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local jwebb = import '../../helper/jwebb.libsonnet';
local supportedCountries = import 'countries.json';

// Add metrics here
local metrics = [
  {
    name: 'trips',
    title: 'Trip Starts',
    query: 'select country_id, time_bucket, count from jwebb.trips_count_country where $timeFilter and country_id = $country_id order by time_bucket asc',
  },
];

local rows = [
  row.new(metric.title).addPanels([jwebb.newPanel(metric, '$country_id', coverage=0.9999)])
  for metric in metrics
];

grafana.dashboard.new(
  'Per Country Metrics',
  uid='per_country',
  refresh='15m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now+2d',
  tags=['generated'],
  editable=true,
)

.addTemplate(
  template.custom(
    name='country_id',
    label='Country',
    query=std.join(',', [std.toString(k.id) for k in supportedCountries]),
    valuelabels={
      [std.toString(k.id)]: k.name
      for k in supportedCountries
    },
    current=std.toString(supportedCountries[0].id),
  )
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
            'type:country',
            'country_id:$country_id',
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
      {
        datasource: {
          type: 'datasource',
          uid: 'grafana',
        },
        enable: true,
        hide: true,
        iconColor: 'purple',
        name: 'Deployment',
        query: 'SELECT\n  toUInt32(ts) * 1000 AS time,\n  description AS text,\n  tags\nFROM\n  event_table\nWHERE\n  ts >= toDateTime($from) AND ts < toDateTime($to)\n',
        target: {
          limit: 100,
          matchAny: false,
          tags: [
            'app-sync-succeeded',
          ],
          type: 'tags',
        },
      },
    ],
  },
}
