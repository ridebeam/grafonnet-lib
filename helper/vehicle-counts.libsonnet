local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local panel = import '../helper/panel.libsonnet';
local gcp = import '../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;


local targets = {
  vehicles: {
    countAll: gcp.counter(
      alias='vehicle-counts',
      aligner='ALIGN_COUNT',
      metric=m('vehicle-count'),
      filters=gcp.combineFilters(gcp.likeFilter(l('versions'), '[0-9]+,[0-9]+,[0-9]+'), gcp.likeFilter(l('city_id'), '$city_id')),
      groupBys=[l('city_id')],
      withServiceFilters=false,
    ),
    byCity: gcp.counter(
      alias='vehicle-counts',
      aligner='ALIGN_COUNT',
      metric=m('vehicle-count'),
      filters=gcp.combineFilters(gcp.likeFilter(l('versions'), '[0-9]+,[0-9]+,[0-9]+'), gcp.likeFilter(l('city_id'), '$city_id')),
      groupBys=[l('city_id'), l('versions')],
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
    )
  },
};

local panels = {
  vehicles: {
    all: panel.fullRow(panel.showTable(panel.counter(title='Vehicle all', format='none').addTargets([
      targets.vehicles.countAll,
    ]), current=true, sort='current')),
    byCity: panel.fullRow(panel.showTable(panel.counter(title='Vehicles by city',
                          format='none',
                          repeat='city_id',
                          repeatDirection='v',
                          legend_sortDesc=true,).addTargets([
      targets.vehicles.byCity,
    ]), current=true, sort='current')),
  },
  startTrip: {
    success: panel.halfRow(panel.showTable(panel.counter(title='Start trip success', format='none').addTargets([
      targets.startTrip.success,
    ]), current=true, sort='current')),
    err: panel.halfRow(panel.showTable(panel.counter(title='Start trip error', format='none').addTargets([
      targets.startTrip.err,
    ]), current=true, sort='current')),
    timing: panel.halfRow(panel.showTable(panel.timeLinear(title='Start trip timing', format='none').addTarget(
      targets.startTrip.timing.p95,
    ), current=true, sort='current')),
  },
};

local rows = {
  summary: row.new('All Vehicles').addPanels([panels.vehicles.all]),
  vehicles: row.new('Vehicles per city').addPanels([
    panels.vehicles.byCity
  ]),
  startTrip: row.new('Start Trip').addPanels([panels.startTrip.success, panels.startTrip.err, panels.startTrip.timing]),
};

{
  dashboard(uid, cities, env)::
    local cityIds = std.objectFields(cities);
    grafana.dashboard.new(
      'Vehicle Counts',
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
    ]),
}
