local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local target = helpers.target;
local panel = helpers.panel;

local cityIdCityName = import '../../data/prod-cityId-cityName.json';
local cityIdcountryName = import '../../data/prod-cityId-countryName.json';
local cityIds = std.objectFields(cityIdCityName);
local countryNames = std.set(std.objectValues(cityIdcountryName));

local cityPanel(cityId, cityName) =
  panel.new(title='Number of trips start at ' + cityName, time_shift='5m')
    .addTargets([
      target.target(
        database='live_business',
        query="SELECT $timeSeries AS t, sum(count) as c FROM $table  WHERE $timeFilter and city_id='"+cityId+"' GROUP BY t ORDER BY t ASC",
        table='trips_start_count',
      )
    ]);

local panels(countryName) = {
  panels: [
    cityPanel(cityId, cityIdCityName[cityId])
    for cityId in std.filter(function(cityId) cityIdcountryName[cityId] == countryName, cityIds)
  ]
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Trips By City All',
  uid='jwebb_trips_by_city_all',
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
