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
  trips_end_by_city_threshold: {
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
      type: 'lt',
      params: [
        0
      ]
    },
    operator: {
      type: 'and'
    }
  }   
};

local cityPanel(cityId, cityName) =
  panel.new(title='Number of trips end at ' + cityName, time_shift='5m')
    .addTargets([
      target.target(
        database='live_business',
        datasourceUID=clickhouse.dataSourceUIDProd,        
        query="SELECT $timeSeries as t, countMerge(count), max(median_wow) FROM $table WHERE $timeFilter AND event_name = 'TRIP_END_SUCCESS' AND city_id='"+cityId+"' GROUP BY t ORDER BY t",
        table='final_30',
      ),
      target.target(
        database='live_business',
        datasourceUID=clickhouse.dataSourceUIDProd,        
        query="SELECT $timeSeries as t, countMerge(count) - max(threshold_1Z) FROM $table WHERE $timeFilter AND event_name = 'TRIP_END_SUCCESS' AND city_id='"+cityId+"' GROUP BY t ORDER BY t",
        table='final_30',
      ),
    ])
    .addAlert(
      name='Number of trips end at ' + cityName + ' is below threshold',
      forDuration='1m',
      frequency='5m',
      notifications=[alertsHelper.slackBusinessMonitoring],
    )
    .addConditions([alertConditions.trips_end_by_city_threshold]);

local panels(countryName) = {
  panels: [
    cityPanel(cityId, cityIdCityName[cityId])
    for cityId in std.filter(function(cityId) cityIdcountryName[cityId] == countryName, cityIds)
  ]
};

local rows = {
  trips: row.new('Trips Health').addPanels([
    panel.fullRow(p)
    for p in panels.cities
  ]),
};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Trips End By City with threshold',
  uid='jwebb_trips_end_by_city_threshold_30m',
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