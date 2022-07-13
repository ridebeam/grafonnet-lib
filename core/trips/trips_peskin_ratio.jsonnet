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
  trips_peskin_ratio: {
    type: 'query',
    query: {
      params: [
        'B',
        '30m',
        'now'
      ]
    },
    reducer: {
      type: 'avg',
      params: []
    },
    evaluator: {
      type: 'gt',
      params: [
        0.1
      ]
    },
    operator: {
      type: 'and'
    }
  }   
};

local cityPanel(cityId, cityName) =
  panel.new(title="Trips' Peskin Ratio at "+ cityName, time_shift='5m')
    .addTargets([
      target.target(
        database='live_business',
        datasourceUID=clickhouse.dataSourceUIDProd,        
        query="SELECT $timeSeries as t, sum(case when status_type = 'failed_rides' then count else 0 end) as failed_rides, sum(case when status_type = 'successful_rides' then count else 0 end) as successful_rides FROM $table WHERE $timeFilter AND city_id='"+cityId+"' GROUP BY t ORDER BY t",
        table='trips_peskin_ratio_30m',
        formattedQuery="SELECT $timeSeries as t, sum(case when status_type = 'failed_rides' then count else 0 end) as failed_rides, sum(case when status_type = 'successful_rides' then count else 0 end) as successful_rides FROM $table WHERE $timeFilter AND city_id='"+cityId+"' GROUP BY t ORDER BY t",
      ),
      target.target(
        database='live_business',
        datasourceUID=clickhouse.dataSourceUIDProd,        
        query="SELECT $timeSeries as t, sum(case when status_type = 'failed_rides' then count else 0 end) / sum(case when status_type = 'successful_rides' then count else 0 end) as peskin_ratio FROM $table WHERE $timeFilter AND city_id='"+cityId+"' GROUP BY t ORDER BY t",
        table='trips_peskin_ratio_30m',
        formattedQuery="SELECT $timeSeries as t, sum(case when status_type = 'failed_rides' then count else 0 end) / sum(case when status_type = 'successful_rides' then count else 0 end) as peskin_ratio FROM $table WHERE $timeFilter AND city_id='"+cityId+"' GROUP BY t ORDER BY t",
      ),
    ])
    .addAlert(
      name='Trips peskin ratio at ' + cityName + ' alert',
      message='Peskin ratio at ' + cityName + ' is above 0.1, number of failed trips are greater than 10% of successful trips in the last 30 minutes.',
      forDuration='1m',
      frequency='5m',
      notifications=[alertsHelper.slackBusinessMonitoring],
      executionErrorState='keep_state',
      noDataState='keep_state',
    )
    .addConditions([alertConditions.trips_peskin_ratio]);

local panels(countryName) = {
  panels: [
    cityPanel(cityId, cityIdCityName[cityId])
    for cityId in std.filter(function(cityId) cityIdcountryName[cityId] == countryName, cityIds)
  ]
};

local rows = {
  trips: row.new("Trips' Peskin Ratio by Cities").addPanels([
    panel.fullRow(p)
    for p in panels.cities
  ]),
};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  "Trips' Peskin Ratio by Cities",
  uid='jwebb_trips_peskin_ratio_by_cities',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  row.new(countryName).addPanels([
    panel.quarterRow(p)
    for p in panels(countryName).panels
  ])
  for countryName in countryNames
])
