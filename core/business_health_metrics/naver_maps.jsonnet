local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';

local helpers = clickhouse.init();
local target = helpers.target;
local panel = helpers.panel;

local panels = {
  vehiclePanel: panel.new(title='Load Vehicles From Backend')
                         .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT 
            (event_time) AS event_time, 
            JSONExtractString(properties, 'timing') AS timing, 
            JSONExtractInt(properties, 'vehicleCount') AS vehicle_count 
            FROM jwebb.events 
            WHERE event_name = 'fetchVehiclesNearby'",
      table='events',
    ),
  ]),
  parkingPanel: panel.new(title='Load Parking Spots From Backend')
                         .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT 
            (event_time) AS event_time, 
            JSONExtractString(properties, 'timing') AS timing, 
            JSONExtractInt(properties, 'vehicleCount') AS vehicle_count 
            FROM jwebb.events 
            WHERE event_name = 'fetchVehiclesNearby'",
      table='events',
    ),
  ]),
  processVehicleAndParkingPanel: panel.new(title='Process Vehicles & Parking Spots')
                         .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT 
            (event_time) AS event_time, 
            JSONExtractString(properties, 'timing') AS timing, 
            JSONExtractInt(properties, 'vehicleCount') AS vehicle_count 
            FROM jwebb.events 
            WHERE event_name = 'fetchVehiclesNearby'",
      table='events',
    ),
  ]),
  geofencesPannel: panel.new(title='Load Geofences')
                         .addTargets([
    target.target(
      database='jwebb',
      datasourceUID=clickhouse.dataSourceUIDProd,
      query="SELECT 
            (event_time) AS event_time, 
            JSONExtractString(properties, 'timing') AS timing, 
            JSONExtractInt(properties, 'vehicleCount') AS vehicle_count 
            FROM jwebb.events 
            WHERE event_name = 'fetchVehiclesNearby'",
      table='events',
    ),
  ])
};

local rows = {
  funnel: row.new('Naver Metrics').addPanels([
    panel.halfRow(panels.vehiclePanel),
    panel.halfRow(panels.parkingPanel),
    panel.halfRow(panels.processVehicleAndParkingPanel),
    panel.halfRow(panels.geofencesPannel),
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Naver Maps',
  uid='naver_maps_metrics',
  refresh='5m',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)

.addRows([
  rows.funnel,
])
