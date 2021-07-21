local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local panel = import '../helper/panel.libsonnet';
local gcp = import '../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;


local targets = {
  vehicles: {
    countAll: gcp.gauges(
      'custom.googleapis.com/opencensus/vehicle-count',
      filters=gcp.combineFilters(gcp.likeFilter(l('city_id'), '$city_id'), gcp.likeFilter(l('controller_version'), '[0-9]+')),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    byCity: gcp.gauges(
      'custom.googleapis.com/opencensus/vehicle-count',
      filters=gcp.combineFilters(gcp.likeFilter(l('city_id'), '$city_id'), gcp.likeFilter(l('controller_version'), '[0-9]+')),
      groupBys=[l('city_id'), l('iot_version'), l('display_version'), l('controller_version')],
      withServiceFilters=false,
    ),
  },
  startTrip: {
    success: gcp.counter(
      alias='start-trip-success',
      metric=m('start-trip'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    err: gcp.counter(
      alias='start-trip-error',
      metric=m('start-trip-error'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    timing: gcp.timers(
      metric=m('start-trip-timing'),
      groupBys=[l('city_id')],
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      withServiceFilters=false,
    ),
  },
  endTrip: {
    success: gcp.counter(
      alias='end-trip-success',
      metric=m('end-trip'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    err: gcp.counter(
      alias='end-trip-error',
      metric=m('end-trip-error'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    timing: gcp.timers(
      metric=m('end-trip-timing'),
      groupBys=[l('city_id')],
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      withServiceFilters=false,
    ),
  },
  collect: {
    success: gcp.counter(
      alias='collect-success',
      metric=m('collect'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    err: gcp.counter(
      alias='collect-error',
      metric=m('collect-error'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    timing: gcp.timers(
      metric=m('collect-timing'),
      groupBys=[l('city_id')],
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      withServiceFilters=false,
    ),
  },
  deploy: {
    success: gcp.counter(
      alias='deploy-success',
      metric=m('deploy'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    err: gcp.counter(
      alias='deploy-error',
      metric=m('deploy-error'),
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    timing: gcp.timers(
      metric=m('deploy-timing'),
      groupBys=[l('city_id')],
      filters=gcp.likeFilter(l('city_id'), '$city_id'),
      withServiceFilters=false,
    ),
  },
};

local panels = {
  vehicles: {
    all: panel.fullRow(panel.showTable(panel.counter(title='Vehicle all', format='none').addTargets([
      targets.vehicles.countAll.sum,
    ]), current=true, sort='current')),
    byCity: panel.repeatPanel(panel.fullRow(panel.showTable(panel.counter(title='Vehicles in ' + '$city_id', format='none', legend_sortDesc=true).addTargets([targets.vehicles.byCity.avg]), current=true, sort='current')), 'city_id', 'v'),
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
      rows.startTrip,
      rows.endTrip,
      rows.collect,
      rows.deploy,
    ]),
}
