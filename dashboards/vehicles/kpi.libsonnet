local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local template = grafana.template;
local panel = import '../helper/panel.libsonnet';
local gcp = import '../../helper/gcp.libsonnet';

local helpers = gcp.init();
local target = helpers.target;
local panel = helpers.panel;
local m = target.customMetric;
local l = target.label;

local filters = {
  city: target.combineFilters(target.envFilter, target.likeFilter(l('city_id'), '$city_id')),
  controllerVersion: target.likeFilter(l('controller_version'), '[0-9]+'),
};

{
  targets:: {
    startTrip: {
      success: target.counter(
        alias='start-trip-success',
        metric=m('start-trip'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      err: target.counter(
        alias='start-trip-error',
        metric=m('start-trip-error'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      timing: target.timers(
        metric=m('start-trip-timing'),
        groupBys=[l('city_id')],
        filters=filters.city,
        withServiceFilters=false,
      ),
    },
    endTrip: {
      success: target.counter(
        alias='end-trip-success',
        metric=m('end-trip'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      err: target.counter(
        alias='end-trip-error',
        metric=m('end-trip-error'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      timing: target.timers(
        metric=m('end-trip-timing'),
        groupBys=[l('city_id')],
        filters=filters.city,
        withServiceFilters=false,
      ),
    },
    collect: {
      success: target.counter(
        alias='collect-success',
        metric=m('collect'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      err: target.counter(
        alias='collect-error',
        metric=m('collect-error'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      timing: target.timers(
        metric=m('collect-timing'),
        groupBys=[l('city_id')],
        filters=filters.city,
        withServiceFilters=false,
      ),
    },
    deploy: {
      success: target.counter(
        alias='deploy-success',
        metric=m('deploy'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      err: target.counter(
        alias='deploy-error',
        metric=m('deploy-error'),
        filters=filters.city,
        groupBys=[l('city_id')],
        withServiceFilters=false,
      ),
      timing: target.timers(
        metric=m('deploy-timing'),
        groupBys=[l('city_id')],
        filters=filters.city,
        withServiceFilters=false,
      ),
    },
    errorCode: {
      errorCode: target.counter(
        metric=m('error-code'),
        groupBys=[l('city_id')],
      ),
    },
    batteryLock: {
      batteryLock: target.counter(
        metric=m('battery-lock'),
        groupBys=[l('city_id')],
      ),
    },
  },

  panels:: {
    local targets = $.targets,

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
  },

  rows:: {
    local panels = $.panels,

    startTrip: row.new('Start Trip').addPanels([panels.startTrip.success, panels.startTrip.err, panels.startTrip.timing]),
    endTrip: row.new('End Trip').addPanels([panels.endTrip.success, panels.endTrip.err, panels.endTrip.timing]),
    collect: row.new('End Trip').addPanels([panels.collect.success, panels.collect.err, panels.collect.timing]),
    deploy: row.new('End Trip').addPanels([panels.deploy.success, panels.deploy.err, panels.deploy.timing]),
    errorCode: row.new('Error Code').addPanels([panels.errorCode.errorCode]),
    batteryLock: row.new('Battery Lock').addPanels([panels.batteryLock.batteryLock]),
  },
}
