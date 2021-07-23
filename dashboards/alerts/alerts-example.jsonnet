local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local panel = import '../../helper/panel.libsonnet';
local gcp = import '../../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;

local filters = {
  service: gcp.combineFilters(
    gcp.equalsFilter('resource.label.namespace_name', 'production'),
    gcp.equalsFilter('resource.label.container_name', 'vehicle-controller'),
  ),
};

local targets = {
  state: {
    changeErrors: gcp.counter(
      metric=m('state-changed-error'),
      groupBys=[l('state_name')],
      filters=filters.service,
      withServiceFilters=false,
    ),
  },
  vehicles: {
    disconnects: gcp.counter(
      metric=m('iot-disconnected'),
      groupBys=[l('city_id')],
      filters=filters.service,
      withServiceFilters=false,
    ),
  },
};

local panels = {
  state: {
    changeErrors: panel.counter('Errors').addTargets([
      targets.state.changeErrors,
    ])
    .addAlert(
      'State error alerts',
      notifications=alerts.notifications,
      message='state errors above 1',
    )
    .addConditions([
      alerts.newCondition(threshold=0.1, thresholdType='gt'),
    ]),
  },
  vehicles: {
    disconnects: panel.counter('Disconnects').addTargets([
      targets.vehicles.disconnects,
    ])
    .addAlert(
      'Vehicle error alerts',
      notifications=alerts.notifications,
      message='disconnects errors above 1',
    )
    .addConditions([
      alerts.newCondition(threshold=1, thresholdType='gt'),
    ]),
  },
};

local rows = {
  state: row.new('State').addPanels([
    panel.fullRow(panels.state.changeErrors),
  ]),
  vehicles: row.new('Vehicles').addPanels([
    panel.fullRow(panels.vehicles.disconnects),
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'alerts-example',
  uid='alerts-example',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  rows.state,
  rows.vehicles,
])
