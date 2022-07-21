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

local targets = {
  rftByCity: target.target(
        database='jwebb',
        datasourceUID=clickhouse.dataSourceUIDProd,
        query='SELECT $timeSeries as t, max(count) FROM $table WHERE $timeFilter AND city_id = $city_id GROUP BY t, city_id ORDER BY t',
        formattedQuery='SELECT $timeSeries as t, max(count) FROM $table WHERE $timeFilter AND city_id = $city_id GROUP BY t, city_id ORDER BY t',
        table='rft_count_30m_v',
    ),
};

local alertConditions = {
  rftByCity: {
    type: 'query',
    query: {
      params: [
        'A',
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
        1,
      ],
    },
    operator: {
      type: 'and',
    },
  },
};

local panels = {
  rftByCity: panel.new(title='Number of rider first trips', time_shift='5m')
    .addTargets([targets.rftByCity])
    .addAlert(
        name='Number of rider first trips at ${city_id} is below threshold',
        forDuration='1m',
        frequency='5m',
        notifications=[alertsHelper.slackBusinessMonitoring],
        executionErrorState='keep_state',
    )
    .addConditions([alertConditions.rftByCity]),
};

local rows = {
  rftByCity: row.new('Rider First Trips').addPanels([
    panel.fullRow(panels.rftByCity),
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Rider First Trip By City Analysis',
  uid='jwebb_rft_by_city_analysis',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  rows.rftByCity,
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
