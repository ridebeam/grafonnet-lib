local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import 'clickhouse.libsonnet';
local alertsHelper = import 'alerts.libsonnet';
local vizHelper = import 'viz.libsonnet';

local helpers = clickhouse.init();
local panel = helpers.panel;
local target = helpers.target;

local pastQuery(metric, coverage=0.99) =
  |||
    select
        (toUInt32(toDateTime(time_bucket)) * 1000) as t,
        if(city_id in (1, 51),
            if(toHour(toDateTime(time_bucket)) between 5 and 15, yhat_lower*0.5, if(yhat_lower < 0, 0, yhat_lower)),
            if(yhat_lower < 0, 0, yhat_lower)
        ) as yhat_lower,
        yhat_upper,
        if(toDateTime(time_bucket) < toStartOfInterval(now(), INTERVAL 30 minute), y, null) as y,
        if(toDateTime(time_bucket) < toStartOfInterval(now(), INTERVAL 30 minute) and y < yhat_lower, y, null) as anomaly_negative,
        if(toDateTime(time_bucket) < toStartOfInterval(now(), INTERVAL 30 minute) and y > yhat_upper, y, null) as anomaly_positive
    from executable(
        'table_forecast_multi.py %(metric)s %(coverage)f',
        'TabSeparated',
        'city_id UInt64, time_bucket String, y Float64, yhat Float64, yhat_lower Float64, yhat_upper Float64',
        (%(query)s))
  ||| % { metric: metric.name, query: metric.query, coverage: coverage }
;

local futureQuery(metric, cityId) =
  |||
    WITH
    time_buckets as (
      SELECT arrayJoin(timeSlots(now(), toUInt32($to-toUInt32(now())), 1800)) AS time_bucket
    )
    select
        (toUInt32(toDateTime(time_bucket)) * 1000) as t,
        yhat as future_yhat
    from executable(
        'table_forecast_multi.py %(metric)s',
        'TabSeparated',
        'city_id UInt64, time_bucket String, y Float64, yhat Float64, yhat_lower Float64, yhat_upper Float64',
        (select %(cityId)s as city_id, time_bucket, 0 as y from time_buckets order by time_bucket asc))
  ||| % { metric: metric.name, cityId: cityId }
;

local overrides = [
  vizHelper.fieldOverride('yhat_upper', {
    custom: {
      fillBelowTo: 'yhat_lower',
      lineWidth: 0,
      fillOpacity: 20,
      lineInterpolation: 'linear',
      gradientMode: 'none',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'super-light-blue',
    },
    displayName: 'Threshold',
    min: 0,
  }),
  vizHelper.fieldOverride('yhat_lower', {
    custom: {
      lineWidth: 0,
      fillOpacity: 0,
      lineInterpolation: 'linear',
      hideFrom: {
        tooltip: false,
        viz: false,
        legend: true,
      },
    },
    min: 0,
  }),
  vizHelper.fieldOverride('yhat', {
    custom: {
      fillOpacity: 0,
      lineWidth: 0,
      lineInterpolation: 'linear',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'dark-blue',
    },
    displayName: 'Forecasted trips',
    min: 0,
  }),
  vizHelper.fieldOverride('y', {
    custom: {
      fillOpacity: 0,
      lineWidth: 2,
      pointSize: 0,
      lineInterpolation: 'linear',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'dark-blue',
    },
    displayName: 'Trips',
    min: 0,
  }),
  vizHelper.fieldOverride('anomaly_positive', {
    custom: {
      fillOpacity: 0,
      lineWidth: 0,
      pointSize: 8,
      showPoints: 'always',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'green',
    },
    displayName: 'Anomaly (positive)',
    min: 0,
  }),
  vizHelper.fieldOverride('anomaly_negative', {
    custom: {
      fillOpacity: 0,
      lineWidth: 0,
      pointSize: 8,
      showPoints: 'always',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'red',
    },
    displayName: 'Anomaly (negative)',
    min: 0,
  }),
  vizHelper.fieldOverride('future_yhat_upper', {
    custom: {
      fillBelowTo: 'future_yhat_lower',
      lineWidth: 0,
      fillOpacity: 20,
      lineInterpolation: 'linear',
      gradientMode: 'none',
    },
    color: {
      mode: 'fixed',
      fixedColor: 'orange',
    },
    displayName: 'Threshold',
    min: 0,
  }),
  vizHelper.fieldOverride('future_yhat_lower', {
    custom: {
      lineWidth: 0,
      fillOpacity: 0,
      lineInterpolation: 'linear',
      hideFrom: {
        tooltip: false,
        viz: false,
        legend: true,
      },
    },
    min: 0,
  }),
  vizHelper.fieldOverride('future_yhat', {
    custom: {
      fillOpacity: 0,
      lineWidth: 2,
      lineInterpolation: 'linear',
      lineStyle: {
        fill: 'dash',
        dash: [10, 10],
      },
    },
    color: {
      mode: 'fixed',
      fixedColor: 'dark-blue',
    },
    displayName: 'Forecasted trips',
    min: 0,
  }),
];

local newPastTarget(metric, cityId, coverage) =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=pastQuery(metric, coverage),
    table='events',
    dateTimeColDataType='time_bucket',
  )
;

local newFutureTarget(metric, cityId) =
  target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=futureQuery(metric, cityId),
    table='events',
    dateTimeColDataType='time_bucket',
  )
;

local newPanel(metric, cityId, coverage) =
  panel.fullRow(
    panel.new(title=metric.title)
    .addTargets([newPastTarget(metric, cityId, coverage), newFutureTarget(metric, cityId)])
    .addOverrides(overrides)
  )
;

{
  newPanel(metric, cityId, coverage=0.99)::
    newPanel(metric, cityId, coverage),
}
