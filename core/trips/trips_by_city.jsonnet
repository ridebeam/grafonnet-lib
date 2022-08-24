local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';
local alertsHelper = import '../../helper/alerts.libsonnet';

local helpers = clickhouse.init();
local target = helpers.target;
local panel = helpers.panel;

local cityIdCityName = import '../../data/prod-cityId-cityName.json';
local cityIdcountryName = import '../../data/prod-cityId-countryName.json';
local cityIds = std.objectFields(cityIdCityName);
local countryNames = std.set(std.objectValues(cityIdcountryName));

local alertConditions = {
  trips_by_city_threshold: {
    type: 'query',
    query: {
      params: [
        'B',
        '30m',
        'now',
      ],
    },
    reducer: {
      type: 'avg',
      params: [],
    },
    evaluator: {
      type: 'lt',
      params: [
        0,
      ],
    },
    operator: {
      type: 'and',
    },
  },
  trips_peskin_ratio: {
    type: 'query',
    query: {
      params: [
        'B',
        '30m',
        'now',
      ],
    },
    reducer: {
      type: 'avg',
      params: [],
    },
    evaluator: {
      type: 'gt',
      params: [
        0.1,
      ],
    },
    operator: {
      type: 'and',
    },
  },
};

local panels = {
  trips_start_threshold: panel.new(title='Number of trips start with threshold', time_shift='5m')
                         .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, max(count), max(median_wow) FROM $table WHERE $timeFilter AND event_name = 'TRIP_START_SUCCESS' AND city_id = $city_id GROUP BY t, city_id ORDER BY t",
      table='trips_start_wow_final_v',
    ),
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, max(count - threshold_1Z) FROM $table WHERE $timeFilter AND event_name = 'TRIP_START_SUCCESS' AND city_id = $city_id GROUP BY t, city_id ORDER BY t",
      table='trips_start_wow_final_v',
    ),
  ])
                         .addAlert(
    name='Number of trips start at ${city_id} is below threshold',
    forDuration='1m',
    frequency='5m',
    notifications=[alertsHelper.slackBusinessMonitoring],
    executionErrorState='keep_state',
  )
                         .addConditions([alertConditions.trips_by_city_threshold]),
  trips_end_threshold: panel.new(title='Number of trips end with threshold', time_shift='5m')
                       .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, max(count), max(median_wow) FROM $table WHERE $timeFilter AND event_name = 'TRIP_END_SUCCESS' AND city_id = $city_id GROUP BY t, city_id ORDER BY t",
      table='trips_end_wow_final_v',
    ),
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, max(count - threshold_1Z) FROM $table WHERE $timeFilter AND event_name = 'TRIP_END_SUCCESS' AND city_id = $city_id GROUP BY t, city_id ORDER BY t",
      table='trips_end_wow_final_v',
    ),
  ])
                       .addAlert(
    name='Number of trips end at ${city_id} is below threshold',
    forDuration='1m',
    frequency='5m',
    notifications=[alertsHelper.slackBusinessMonitoring],
    executionErrorState='keep_state',
  )
                       .addConditions([alertConditions.trips_by_city_threshold]),
  trips_peskin_ratio: panel.new(title="Trips' Peskin Ratio", time_shift='5m')
                      .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, sum(case when status_type = 'failed_rides' then count else 0 end) as failed_rides, sum(case when status_type = 'successful_rides' then count else 0 end) as successful_rides FROM $table WHERE $timeFilter AND city_id=$city_id GROUP BY t, city_id ORDER BY t",
      table='trips_peskin_ratio_30m_v',
    ),
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT $timeSeries as t, sum(case when status_type = 'failed_rides' then count else 0 end) / sum(case when status_type = 'successful_rides' then count else 0 end) as peskin_ratio FROM $table WHERE $timeFilter AND city_id=$city_id GROUP BY t, city_id ORDER BY t",
      table='trips_peskin_ratio_30m_v',
    ),
  ])
                      .addAlert(
    name='Trips peskin ratio at ${city_id} alert',
    message='Peskin ratio at ${city_id} is above 0.1, number of failed trips are greater than 10% of successful trips in the last 30 minutes.',
    forDuration='1m',
    frequency='5m',
    notifications=[alertsHelper.slackBusinessMonitoring],
    executionErrorState='keep_state',
    noDataState='keep_state',
  )
                      .addConditions([alertConditions.trips_peskin_ratio]),
};

local rows = {
  trips_start_with_threshold: row.new('Trips start with threshold').addPanels([
    panel.fullRow(panels.trips_start_threshold),
  ]),
  trips_end_with_threshold: row.new('Trips end with threshold').addPanels([
    panel.fullRow(panels.trips_end_threshold),
  ]),
  trips_peskin_ratio: row.new('Trips Peskin Ratio').addPanels([
    panel.fullRow(panels.trips_peskin_ratio),
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Trips By City Analysis',
  uid='jwebb_trips_by_city_analysis',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  rows.trips_start_with_threshold,
  rows.trips_end_with_threshold,
  rows.trips_peskin_ratio,
])

.addTemplate(
  template.custom(
    name='city_id',
    label='city_id',
    query=std.join(',', cityIds),
    valuelabels=cityIdCityName,
    current='12',
  )
)
