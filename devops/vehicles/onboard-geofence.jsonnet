local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local libProm = grafana.prometheus;
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local envFilter = target.equalsFilter('namespace', '$env');
local filterVehicleController = target.combineFilters(
  envFilter,
  target.equalsFilter('service', 'vehicle-controller'),
);

local filterIotServer = target.combineFilters(
  envFilter,
  target.equalsFilter('service', 'iot-server'),
);

local filterVehicleTasks = target.combineFilters(
  envFilter,
  target.equalsFilter('service', 'vehicle-tasks'),
);

local targets = {
  // moved in the top 2 panels controller
  requestUrl: {
    requested: target.increase(
      alias='requested',
      metric='state-change-request',
      filters=target.combineFilters(
        filterVehicleController,
        target.equalsFilter('state_name', 'onboardGeofenceRequestURL'),
      ),
      withServiceFilters=false,
    ),
    completed: target.increase(
      alias='completed',
      metric='state-changed',
      filters=target.combineFilters(
        filterVehicleController,
        target.equalsFilter('state_name', 'onboardGeofenceRequestURL'),
      ),
      withServiceFilters=false,
    ),
    U6Succeeded: target.increase(
      alias='og-succeeded',
      metric='onboard-geofence-upgrade-succeeded',
      filters=filterIotServer,
      withServiceFilters=false,
    ),
    U6Attempts: target.increase(
      alias='og-attempted',
      metric='onboard-geofence-attempt-upgrade',
      filters=filterIotServer,
      withServiceFilters=false,
    ),
    updatingDurationRequestUrl: target.timers(
      metric='state-changed-latency',
      filters=target.combineFilters(
        target.equalsFilter('state_name', 'onboardGeofenceRequestURL'),
        filterVehicleController,
      ),
      withServiceFilters=false,
    ),
  },
  ogcsUpdates: {
    requested: target.increase(
      alias='ogcs-requested',
      metric='onboard-geofence-change-requested',
      filters=filterVehicleController,
      withServiceFilters=false,
    ),
    met: target.increase(
      alias='ogcs-met',
      metric='ogcs-target-met',
      filters=filterIotServer,
      withServiceFilters=false,
    ),
    metPercent: libProm.target(
      '(sum(increase(ogcs_target_met{namespace="$env", service="iot-server"}[2h])))/(sum(increase(onboard_geofence_change_requested{namespace="$env", service="vehicle-controller"}[2h]))) > 0',
      legendFormat='%',
      intervalFactor=2,
    ),
    count: target.increase(
      alias='ogcs-count',
      metric='onboard-geofence-change-settings-count',
      groupBys=['city_id'],
      filters=filterVehicleTasks,
      withServiceFilters=false,
    ),
    updatingDurationOGCS: target.timers(
      metric='state-changed-latency',
      filters=target.combineFilters(
        target.equalsFilter('state_name', 'onboardGeofenceChanges'),
        filterVehicleController,
      ),
      withServiceFilters=false,
    ),
  },
  vehicleTasks: {
    requestUpdateVehicleState: target.increase(
      alias='reportedRequestUrlCount',
      metric='request-update-vehicle-state-count',
      filters=target.combineFilters(
        filterVehicleTasks,
        target.equalsFilter('type_changes', 'onboardGeofenceRequestURL'),
      ),
      withServiceFilters=false,
    ),
    ogRequestUrlLatency: target.timers(
      metric='sending-report-duration',
      filters=target.combineFilters(
        filterVehicleTasks,
        target.equalsFilter('type_changes', 'onboardGeofenceRequestURL'),
      ),
      withServiceFilters=false,
    ),
    ogChangesLatency: target.timers(
      metric='sending-report-duration',
      filters=target.combineFilters(
        filterVehicleTasks,
        target.equalsFilter('type_changes', 'onboardGeofenceChanges'),
      ),
      withServiceFilters=false,
    ),
    requestUrlCount: target.increase(
      metric='request-url-count',
      alias='requestUrlCount',
      filters=filterVehicleTasks,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    ogcsCount: target.increase(
      alias='ogcsCount',
      metric='onboard-geofence-change-settings-count',
      filters=filterVehicleTasks,
      withServiceFilters=false,
    ),
    requestUpdateCount: target.increase(
      alias='updateVehicleStateCount',
      metric='request-update-vehicle-state-count',
      filters=target.combineFilters(
        filterVehicleTasks,
        target.equalsFilter('type_changes', 'onboardGeofenceEnabled'),
      ),
      withServiceFilters=false,
    ),
    ogEnabledLatency: target.timers(
      metric='sending-report-duration',
      filters=target.combineFilters(
        filterVehicleTasks,
        target.equalsFilter('type_changes', 'onboardGeofenceEnabled'),
      ),
      withServiceFilters=false,
    ),
  },
};

local panels = {
  requestUrl: {
    requested: panel.counter('Vehicle controller OG RequestURL counts').addTargets([
      targets.requestUrl.requested,
      targets.requestUrl.completed,
    ]),
    U6: panel.counter('Vehicle controller OG RequestURL counts').addTargets([
      targets.requestUrl.U6Succeeded,
      targets.requestUrl.U6Attempts,
    ]),
    ogUrlDownload: panel.timeLinear(title='Onboard Geofence URL Download Duration', points=true, pointradius=1, lines=false).addTargets([
      targets.requestUrl.updatingDurationRequestUrl.p50,
      targets.requestUrl.updatingDurationRequestUrl.p99,
    ]),
  },
  ogcsUpdates: {
    ogcsCompare: panel.counter('OG changed settings fence counts').addTargets([
      targets.ogcsUpdates.requested,
      targets.ogcsUpdates.met,
    ]),
    ogcsPercentage: panel.new(title='OG changed settings fence handled % [2h]', percentage=true).addTargets([
      targets.ogcsUpdates.metPercent,
    ]),
    ogcsCount: panel.counter('VT - Requested OGCS counts by city_id').addTargets([
      targets.ogcsUpdates.count,
    ]),
    ogcsDownload: panel.timeLinear('Onboard Geofence Changes Duration').addTargets([
      targets.ogcsUpdates.updatingDurationOGCS.p50,
      targets.ogcsUpdates.updatingDurationOGCS.p99,
    ]),
  },
  vehicleTasks: {
    reportRequestUrlCount: panel.counter('Count of OG request URL reports').addTargets([
      targets.vehicleTasks.requestUpdateVehicleState,
    ]),
    ogRequestUrlDurationP99P50: panel.timeLinear(title='OG report latencies (p99, p50)', points=true, pointradius=1, lines=false).addTargets([
      targets.vehicleTasks.ogRequestUrlLatency.p99,
      targets.vehicleTasks.ogChangesLatency.p99,
      targets.vehicleTasks.ogRequestUrlLatency.p50,
      targets.vehicleTasks.ogChangesLatency.p50,
    ]),
    requestUrlCount: panel.counter('Vehicle Tasks - number of reports sent by city_id').addTargets([
      targets.vehicleTasks.requestUrlCount,
    ]),
    countOgcs: panel.counter('Count of OGCS').addTarget(
      targets.vehicleTasks.ogcsCount,
    ),
    countOGEnabled: panel.counter('Count of OG Enabled').addTarget(
      targets.vehicleTasks.requestUpdateCount,
    ),
    enabledDuration: panel.timeLinear(title='OG enabled duration (p99)', points=true, pointradius=1, lines=false, nullPointMode='null').addTargets([
      targets.vehicleTasks.ogEnabledLatency.p99,
    ]),
  },
};

local rows = {
  requestUrl: row.new('Request URL').addPanels([
    panel.thirdRow(p)
    for p in [
      panels.requestUrl.requested,
      panels.requestUrl.U6,
      panels.requestUrl.ogUrlDownload,
    ]
  ]),
  ogcsUpdates: row.new('Onboard Geofences Changes Updating').addPanels([
    panel.halfRow(p)
    for p in [
      panels.ogcsUpdates.ogcsCompare,
      panels.ogcsUpdates.ogcsPercentage,
    ] + [
      panel.halfRow(p)
      for p in [
        panels.ogcsUpdates.ogcsCount,
        panels.ogcsUpdates.ogcsDownload,
      ]
    ]
  ]),
  vehicleTasks: row.new('Vehicle tasks').addPanels(
    [
      panel.halfRow(p)
      for p in [
        panels.vehicleTasks.reportRequestUrlCount,
        panels.vehicleTasks.ogRequestUrlDurationP99P50,
      ]
    ] + [
      panel.halfRow(p)
      for p in [
        panels.vehicleTasks.requestUrlCount,
        panels.vehicleTasks.countOgcs,
      ]
    ] + [
      panel.halfRow(p)
      for p in [
        panels.vehicleTasks.countOGEnabled,
        panels.vehicleTasks.enabledDuration,
      ]
    ]
  ),
};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'onboard-geofence',
  uid='vehicle-domain_onboard-geofence_promql',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addTemplate(
  template.custom(
    name='env',
    query='dev,stable,staging,production',
    current='production',
  )
)

.addRows([
  rows.requestUrl,
  rows.ogcsUpdates,
  rows.vehicleTasks,
])
