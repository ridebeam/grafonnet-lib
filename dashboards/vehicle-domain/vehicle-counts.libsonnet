local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local countsSD = import './vehicle-counts-stackdriver.libsonnet';

local filters = {
  city: target.combineFilters(target.envFilter, target.likeFilter('city_id', '$city_id')),
  controllerVersion: target.likeFilter('controller_version', '[0-9]+'),
};

local targets = {
  vehicles: {
    countAll: target.gauges(
      'vehicle-count',
      filters=target.combineFilters(filters.city, filters.controllerVersion),
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    byCity: target.gauges(
      'vehicle-count',
      filters=target.combineFilters(filters.city, filters.controllerVersion),
      groupBys=['city_id', 'iot_version', 'display_version', 'controller_version'],
      withServiceFilters=false,
    ),
  },
  startTrip: {
    success: target.counter(
      alias='start-trip-success',
      metric='start-trip',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    err: target.counter(
      alias='start-trip-error',
      metric='start-trip-error',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    timing: target.timers(
      metric='start-trip-timing',
      groupBys=['city_id'],
      filters=filters.city,
      withServiceFilters=false,
    ),
  },
  endTrip: {
    success: target.counter(
      alias='end-trip-success',
      metric='end-trip',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    err: target.counter(
      alias='end-trip-error',
      metric='end-trip-error',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    timing: target.timers(
      metric='end-trip-timing',
      groupBys=['city_id'],
      filters=filters.city,
      withServiceFilters=false,
    ),
  },
  collect: {
    success: target.counter(
      alias='collect-success',
      metric='collect',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    err: target.counter(
      alias='collect-error',
      metric='collect-error',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    timing: target.timers(
      metric='collect-timing',
      groupBys=['city_id'],
      filters=filters.city,
      withServiceFilters=false,
    ),
  },
  deploy: {
    success: target.counter(
      alias='deploy-success',
      metric='deploy',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    err: target.counter(
      alias='deploy-error',
      metric='deploy-error',
      filters=filters.city,
      groupBys=['city_id'],
      withServiceFilters=false,
    ),
    timing: target.timers(
      metric='deploy-timing',
      groupBys=['city_id'],
      filters=filters.city,
      withServiceFilters=false,
    ),
  },
  errorCode: {
    errorCode: target.counter(
      metric='error-code',
      groupBys=['city_id'],
    ),
  },
  batteryLock: {
    batteryLock: target.counter(
      metric='battery-lock',
      groupBys=['city_id'],
    ),
  },
};

local panels = {
  vehicles: {
    all: panel.fullRow(panel.showTable(panel.counter(title='Vehicle all', format='none').addTargets([
      targets.vehicles.countAll.sum,
    ]), current=true, sort='current')),
    byCity: panel.repeatPanel(panel.fullRow(panel.showTable(
      panel.counter(title='Vehicles in ' + '$city_id', format='none', legend_sortDesc=true).addTargets([
        targets.vehicles.byCity.avg,
      ]), current=true, sort='current'
    )), 'city_id', 'v'),
  },
  startTrip: {
    success: panel.halfRow(panel.showTable(panel.counter(title='Start trip success').addTargets([
      targets.startTrip.success,
    ]), current=true, sort='current')),
    err: panel.halfRow(panel.showTable(panel.counter(title='Start trip error').addTargets([
      targets.startTrip.err,
    ]), current=true, sort='current')),
    timing: panel.halfRow(panel.showTable(panel.timeLinear(title='Start trip timing').addTarget(
      targets.startTrip.timing.p95,
    ), current=true, sort='current')),
  },
  endTrip: {
    success: panel.halfRow(panel.showTable(panel.counter(title='End trip success').addTargets([
      targets.endTrip.success,
    ]), current=true, sort='current')),
    err: panel.halfRow(panel.showTable(panel.counter(title='End trip error').addTargets([
      targets.endTrip.err,
    ]), current=true, sort='current')),
    timing: panel.halfRow(panel.showTable(panel.timeLinear(title='End trip timing').addTarget(
      targets.endTrip.timing.p95,
    ), current=true, sort='current')),
  },
  collect: {
    success: panel.halfRow(panel.showTable(panel.counter(title='Collect success').addTargets([
      targets.collect.success,
    ]), current=true, sort='current')),
    err: panel.halfRow(panel.showTable(panel.counter(title='Collect error').addTargets([
      targets.collect.err,
    ]), current=true, sort='current')),
    timing: panel.halfRow(panel.showTable(panel.timeLinear(title='Collect timing').addTarget(
      targets.collect.timing.p95,
    ), current=true, sort='current')),
  },
  deploy: {
    success: panel.halfRow(panel.showTable(panel.counter(title='Deploy success').addTargets([
      targets.deploy.success,
    ]), current=true, sort='current')),
    err: panel.halfRow(panel.showTable(panel.counter(title='Deploy error').addTargets([
      targets.deploy.err,
    ]), current=true, sort='current')),
    timing: panel.halfRow(panel.showTable(panel.timeLinear(title='Deploy timing').addTarget(
      targets.deploy.timing.p95,
    ), current=true, sort='current')),
  },
  errorCode: {
    errorCode: panel.counter('Error Code').addTargets([
      targets.errorCode.errorCode,
    ]),
  },
  batteryLock: {
    batteryLock: panel.counter('Battery Lock').addTargets([
      targets.batteryLock.batteryLock,
    ]),
  },
};

local rows = {
  summary: row.new('All Vehicles').addPanels([panels.vehicles.all]),
  vehicles: row.new('Vehicles per city').addPanels([
    panels.vehicles.byCity,
  ]),
  startTrip: row.new('Start Trip').addPanels([panels.startTrip.success, panels.startTrip.err, panels.startTrip.timing]),
  endTrip: row.new('End Trip').addPanels([panels.endTrip.success, panels.endTrip.err, panels.endTrip.timing]),
  collect: row.new('End Trip').addPanels([panels.collect.success, panels.collect.err, panels.collect.timing]),
  deploy: row.new('End Trip').addPanels([panels.deploy.success, panels.deploy.err, panels.deploy.timing]),
  errorCode: row.new('Error Code').addPanels([panels.errorCode.errorCode]),
  batteryLock: row.new('Battery Lock').addPanels([panels.batteryLock.batteryLock]),
};

{
  dashboard(uid, cities, env)::
    local cityIds = std.objectFields(cities);
    grafana.dashboard.new(
      'Vehicle Counts ' + env,
      uid=uid,
      refresh='30s',
      timepicker=grafana.timepicker.new() { nowDelay: '1m' },
      time_to='now-1m',
      tags=['overview', 'generic', 'generated']
    )

    .addTemplate(
      template.custom(
        name='env',
        query='staging,production',
        current=env,
        hide='true',
      )
    )

    .addTemplate(
      template.custom(
        name='service',
        query='vehicle-gateway',
        current='vehicle-gateway',
        hide='true',
      )
    )

    .addTemplate(
      template.custom(
        name='city_id',
        query=std.join(',', cityIds),
        valuelabels=cities,
        includeAll=true,
        current='All',
      )
    )

    .addRows([
      rows.summary,
      panel.collapseRow(rows.vehicles),

      // those coming from API still need to be retrieved from GCP Monitoring
      countsSD.rows.startTrip,
      countsSD.rows.endTrip,
      countsSD.rows.collect,
      countsSD.rows.deploy,
      countsSD.rows.errorCode,
      countsSD.rows.batteryLock,
    ]),
}
