local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local gcp = import '../../helper/gcp.libsonnet';

local helpers = gcp.init();
local target = helpers.target;
local panel = helpers.panel;
local m = target.customMetric;
local l = target.label;

local filters = {
  service: target.combineFilters(
    target.equalsFilter('resource.label.namespace_name', 'production'),
    target.equalsFilter('resource.label.container_name', 'vehicle-controller'),
  ),
};

local targets = {
  state: {
    changeErrors: target.counter(
      metric='state-changed-error',
      groupBys=['state_name'],
      filters=filters.service,
      withServiceFilters=false,
    ),
  },
  vehicles: {
    disconnects: target.counter(
      metric='iot-disconnected',
      groupBys=['city_id'],
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
      notifications=alerts.notifications.test,
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
      notifications=alerts.notifications.test,
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
