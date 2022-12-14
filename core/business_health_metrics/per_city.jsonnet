local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local jwebb = import '../../helper/jwebb.libsonnet';
local supportedCities = import 'cities.json';

local paymentsQuery =
  |||
    with
    raw_events as (
      select
        event_time,
        visitParamExtractString(properties, 'itemType') as item_type,
        visitParamExtractInt(properties, 'cityId') as city_id
      from jwebb.events
      where event_name = 'Purchase'
      and item_type = 'Trip'
      and city_id = $city_id
    )
    select
      toString(city_id) as city_id,
      toStartOfInterval(event_time, interval 30 minute) as time_bucket,
      count() as count
    from raw_events
    where $timeFilter
    group by city_id, time_bucket
    order by time_bucket asc
  |||
;

local weatherQuery(weather) =
  |||
    select
      toUInt32(toStartOfInterval(event_time, interval 1 hour))*1000 as time,
      (toUInt32(toStartOfInterval(event_time, interval 1 hour))*1000) + 3600000 as time_end,
      description[1] as text
    from jwebb.weather
    where georegion_id = $city_id
    and event_time >= $from and event_time <= $to
    and text = '%(weather)s'
  ||| % { weather: weather.name }
;

local weatherAnnotation(weather) =
  {
    datasource: {
      type: 'vertamedia-clickhouse-datasource',
      uid: '_Az-rRXnz',
    },
    enable: true,
    name: weather.name,
    iconColor: weather.iconColor,
    query: weatherQuery(weather),
    rawQuery: weatherQuery(weather),
  };

// Grafana does not support overriding color, so we create 1 annotation query per weather
local weathers = [
  // {
  //   name: 'Clouds',
  //   iconColor: '#adadad',
  // },
  {
    name: 'Drizzle',
    iconColor: 'super-light-blue',
  },
  {
    name: 'Rain',
    iconColor: 'blue',
  },
  {
    name: 'Thunderstorm',
    iconColor: '#1b3c6e',
  },
];

// Add metrics here
local metrics = [
  {
    name: 'trips',
    title: 'Trip Starts',
    query: 'select city_id, time_bucket, count from jwebb.trips_count_30m where $timeFilter and city_id = $city_id order by time_bucket asc',
  },
];

local rows = [
  row.new(metric.title).addPanels([jwebb.newPanel(metric, '$city_id')])
  for metric in metrics
];

grafana.dashboard.new(
  'Per City Metrics',
  uid='per_city',
  refresh='15m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-7d',
  time_to='now+2d',
  tags=['generated'],
  editable=true,
)

.addTemplate(
  template.custom(
    name='city_id',
    label='City',
    query=std.join(',', [std.toString(k.id) for k in supportedCities]),
    valuelabels={
      [std.toString(k.id)]: k.name
      for k in supportedCities
    },
    current=std.toString(supportedCities[0].id),
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
            'type:city',
            'city_id:$city_id',
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
    ] + [weatherAnnotation(w) for w in weathers],
  },
}
