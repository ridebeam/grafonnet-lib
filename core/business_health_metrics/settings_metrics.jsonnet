local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local template = grafana.template;
local row = grafana.row;
local bigquery = import '../../helper/bigquery.libsonnet';

local helpers = bigquery.init();
local panel = helpers.panel;
local target = helpers.target;

local supportedCities = import 'cities.json';

local globalSettingsChangesQuery =
  |||
    SELECT
        TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(`vs`.`updated_at`), 300) * 300) AS time_bucket,
        COUNT(vs.id) as count
    FROM `ridebeam-data.liveescooter.vehiclessettings` vs
    WHERE 
        $__timeFilter(vs.updated_at)
    GROUP BY 1
    ORDER BY 1 ASC
  |||
;

local perCitySettingsChangesQuery =
  |||
    SELECT
        TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(`vs`.`updated_at`), 300) * 300) AS time_bucket,
        COUNT(vs.id) as count
    FROM `ridebeam-data.liveescooter.vehiclessettings` vs
    INNER JOIN `ridebeam-data.liveescooter.georegions` g ON g.vehicle_setting_id = vs.id
    WHERE
        g.type = 'GeoFence'
    AND
        $__timeFilter(vs.updated_at) and g.parent_region_id = $city_id
    GROUP BY 1
    ORDER BY 1 ASC
  |||
;

local targets = {
  settingsChanges: {
    global: target.target(
      rawSql=globalSettingsChangesQuery,
    ),
    perCity: target.target(
      rawSql=perCitySettingsChangesQuery,
    ),
  },
};

local panels = {
  settingsChanges: {
    global: panel.new(title='Global')
            .addTargets([targets.settingsChanges.global]),
    perCity: panel.new(title='Per City')
             .addTargets([targets.settingsChanges.perCity]),
  },
};

local rows = {
  settingsChanges: row.new('Settings Changes').addPanels([
    panel.fullRow(p)
    for p in [
      panels.settingsChanges.global,
      panels.settingsChanges.perCity,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Settings Metrics',
  uid='settings_metrics',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now',
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

.addRows([
  rows.settingsChanges,
])
