local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local k8s = import 'k8s.libsonnet';
local panel = import '../helper/panel.libsonnet';
local gcp = import '../helper/gcp-target.libsonnet';
local m = gcp.customMetric;
local l = gcp.label;

local cities = import '../data/staging-cities.json';
local cityIds = std.objectFields(cities);


local targets = {
  vehicles: {
    countAll: gcp.counter(
      alias='vehicle-counts',
      metric=m('vehicle-count'),
      filters=gcp.combineFilters(gcp.likeFilter(l('versions'), '[0-9]+,[0-9]+,[0-9]+'), gcp.likeFilter(l('city_id'), '$city_id')),
      groupBys=[l('city_id')],
    ),
    byCity: gcp.counter(
      alias='vehicle-counts',
      metric=m('vehicle-count'),
      filters=gcp.combineFilters(gcp.likeFilter(l('versions'), '[0-9]+,[0-9]+,[0-9]+'), gcp.likeFilter(l('city_id'), '$city_id')),
      groupBys=[l('city_id'), l('versions')],
    )
  },
};

local panels = {
  vehicles: {
    all: panel.counter(title='Vehicle all', format='none').addTargets([
      targets.vehicles.countAll,
    ]),
    byCity: panel.counter(title='Vehicles by city', format='none',repeat='city_id', repeatDirection='v',
    legend_sortDesc=true,).addTargets([
      targets.vehicles.byCity,
    ]),
  },
};

local rows = {
  summary: row.new('All Vehicles').addPanels([panel.fullRow(panel.showTable(panels.vehicles.all, current=true, sort="current"))]),
  vehicles: row.new('Vehicles per city').addPanels([panel.fullRow(panel.showTable(panels.vehicles.byCity, current=true, sort="current"))
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Vehicle Counts',
  uid='vehicle-count',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['overview', 'generic', 'generated']
)

.addTemplate(
  template.custom(
    name='env',
    query='staging,production',
    current='staging',
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
    query=std.join(",", cityIds),
    valuelabels=cities,
    includeAll=true,
    current='All',
  )
)

.addRows([
  rows.summary,
  panel.collapseRow(rows.vehicles),
])
