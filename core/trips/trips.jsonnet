local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local prom = import '../../helper/promql.libsonnet';
local k8s = import '../k8s-promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;


local targets = {
  serviceUptime: {
    jobmanagerUptime: target.counter(
      metric='flink_jobmanager_job_uptime'
    ),
    jobmanagerDowntime: target.counter(
      metric='flink_jobmanager_job_downtime'
    ),
    checkpointsSucceeded: target.counter(
      metric='flink_jobmanager_job_numberOfCompletedCheckpoints'
    ),
    checkpointsFailed: target.counter(
      metric='flink_jobmanager_job_numberOfFailedCheckpoints'
    ),
  },
};

local panels = {
  allTripsStart: {
       "alert": {
               "alertRuleTags": {},
               "conditions": [
                 {
                   "evaluator": {
                     "params": [
                       40
                     ],
                     "type": "lt"
                   },
                   "operator": {
                     "type": "and"
                   },
                   "query": {
                     "params": [
                       "A",
                       "5m",
                       "now"
                     ]
                   },
                   "reducer": {
                     "params": [],
                     "type": "avg"
                   },
                   "type": "query"
                 }
               ],
               "executionErrorState": "alerting",
               "for": "5m",
               "frequency": "1m",
               "handler": 1,
               "message": "Trips start are low globally (<40)",
               "name": "Number of trips start globally alert",
               "noDataState": "no_data",
               "notifications": [
                 {
                   "uid": "QVVrMvj7z"
                 }
               ]
             },
      "datasource": null,
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 7,
            "gradientMode": "opacity",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "smooth",
            "lineStyle": {
              "fill": "solid"
            },
            "lineWidth": 1,
            "pointSize": 1,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 1
      },
      "id": 2,
      "interval": null,
      "maxDataPoints": null,
      "options": {
        "legend": {
          "calcs": [
            "lastNotNull"
          ],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      },
      "pluginVersion": "8.2.3",
      "targets": [
        {
          "database": "live_business",
          "dateColDataType": "",
          "dateLoading": false,
          "dateTimeColDataType": "time_bucket",
          "dateTimeType": "DATETIME",
          "datetimeLoading": false,
          "extrapolate": true,
          "format": "time_series",
          "formattedQuery": "SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t",
          "interval": "",
          "intervalFactor": 1,
          "query": "SELECT\n    $timeSeries AS t,\n    sum(count) as count\nFROM $table\n\nWHERE $timeFilter\n\nGROUP BY\n    t\nORDER BY t ASC\n",
          "refId": "A",
          "round": "0s",
          "skip_comments": true,
          "table": "trips_start_count",
          "tableLoading": false
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeShift": "5m",
      "title": "Number of trips start globally",
      "type": "timeseries"
    },
  tripsStartBy: {
         "alert": {
                 "alertRuleTags": {},
                 "conditions": [
                   {
                     "evaluator": {
                       "params": [
                         10
                       ],
                       "type": "lt"
                     },
                     "operator": {
                       "type": "and"
                     },
                     "query": {
                       "params": [
                         "A",
                         "5m",
                         "now"
                       ]
                     },
                     "reducer": {
                       "params": [],
                       "type": "avg"
                     },
                     "type": "query"
                   }
                 ],
                 "executionErrorState": "alerting",
                 "for": "1h",
                 "frequency": "1m",
                 "handler": 1,
                 "name": "Number of trips start by city ID alert",
                 "noDataState": "no_data",
                 "notifications": [
                   {
                     "uid": "QVVrMvj7z"
                   }
                 ]
               },
         "datasource": null,
         "fieldConfig": {
           "defaults": {
             "color": {
               "mode": "palette-classic"
             },
             "custom": {
               "axisLabel": "",
               "axisPlacement": "auto",
               "barAlignment": 0,
               "drawStyle": "line",
               "fillOpacity": 7,
               "gradientMode": "opacity",
               "hideFrom": {
                 "legend": false,
                 "tooltip": false,
                 "viz": false
               },
               "lineInterpolation": "smooth",
               "lineStyle": {
                 "fill": "solid"
               },
               "lineWidth": 1,
               "pointSize": 1,
               "scaleDistribution": {
                 "type": "linear"
               },
               "showPoints": "auto",
               "spanNulls": false,
               "stacking": {
                 "group": "A",
                 "mode": "none"
               },
               "thresholdsStyle": {
                 "mode": "off"
               }
             },
             "mappings": [],
             "thresholds": {
               "mode": "absolute",
               "steps": [
                 {
                   "color": "green",
                   "value": null
                 },
                 {
                   "color": "red",
                   "value": 80
                 }
               ]
             }
           },
           "overrides": []
         },
         "gridPos": {
           "h": 9,
           "w": 12,
           "x": 0,
           "y": 9
         },
         "id": 2,
         "interval": null,
         "maxDataPoints": null,
         "options": {
           "legend": {
             "calcs": [
               "lastNotNull"
             ],
             "displayMode": "list",
             "placement": "bottom"
           },
           "tooltip": {
             "mode": "single"
           }
         },
         "pluginVersion": "8.2.3",
         "targets": [
           {
             "database": "live_business",
             "dateColDataType": "",
             "dateLoading": false,
             "dateTimeColDataType": "time_bucket",
             "dateTimeType": "DATETIME",
             "datetimeLoading": false,
             "extrapolate": true,
             "format": "time_series",
             "formattedQuery": "SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t",
             "interval": "",
             "intervalFactor": 1,
             "query": "SELECT\n    $timeSeries AS t,\n    sum(count) as c,\n    city_id\nFROM $table\n\nWHERE $timeFilter\n\nGROUP BY\n    t,\n    city_id\nORDER BY t ASC\n",
             "refId": "A",
             "round": "0s",
             "skip_comments": true,
             "table": "trips_start_count",
             "tableLoading": false
           }
         ],
         "thresholds": [],
         "timeFrom": null,
         "timeShift": "5m",
         "title": "Number of trips start by city ID",
         "type": "timeseries"
       },
  allTripsEnd: {
        "alert": {
                "alertRuleTags": {},
                "conditions": [
                  {
                    "evaluator": {
                      "params": [
                        40
                      ],
                      "type": "lt"
                    },
                    "operator": {
                      "type": "and"
                    },
                    "query": {
                      "params": [
                        "A",
                        "5m",
                        "now"
                      ]
                    },
                    "reducer": {
                      "params": [],
                      "type": "avg"
                    },
                    "type": "query"
                  }
                ],
                "executionErrorState": "alerting",
                "for": "5m",
                "frequency": "1m",
                "handler": 1,
                "message": "Trips end are low globally (<40)",
                "name": "Number of trips end globally alert",
                "noDataState": "no_data",
                "notifications": [
                  {
                    "uid": "QVVrMvj7z"
                  }
                ]
              },
        "datasource": null,
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 7,
              "gradientMode": "opacity",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "smooth",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 1,
              "pointSize": 1,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "auto",
              "spanNulls": false,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": 80
                }
              ]
            }
          },
          "overrides": []
        },
        "gridPos": {
          "h": 7,
          "w": 24,
          "x": 0,
          "y": 1
        },
        "id": 2,
        "interval": null,
        "maxDataPoints": null,
        "options": {
          "legend": {
            "calcs": [
              "lastNotNull"
            ],
            "displayMode": "list",
            "placement": "bottom"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "pluginVersion": "8.2.3",
        "targets": [
          {
            "database": "live_business",
            "dateColDataType": "",
            "dateLoading": false,
            "dateTimeColDataType": "time_bucket",
            "dateTimeType": "DATETIME",
            "datetimeLoading": false,
            "extrapolate": true,
            "format": "time_series",
            "formattedQuery": "SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t",
            "interval": "",
            "intervalFactor": 1,
            "query": "SELECT\n    $timeSeries AS t,\n    sum(count) as count\nFROM $table\n\nWHERE $timeFilter\n\nGROUP BY\n    t\nORDER BY t ASC\n",
            "refId": "A",
            "round": "0s",
            "skip_comments": true,
            "table": "trips_end_count",
            "tableLoading": false
          }
        ],
        "thresholds": [],
        "timeFrom": null,
        "timeShift": "5m",
        "title": "Number of trips end globally",
        "type": "timeseries"
      },
    tripsEndBy: {
            "alert": {
                    "alertRuleTags": {},
                    "conditions": [
                      {
                        "evaluator": {
                          "params": [
                            10
                          ],
                          "type": "lt"
                        },
                        "operator": {
                          "type": "and"
                        },
                        "query": {
                          "params": [
                            "A",
                            "5m",
                            "now"
                          ]
                        },
                        "reducer": {
                          "params": [],
                          "type": "avg"
                        },
                        "type": "query"
                      }
                    ],
                    "executionErrorState": "alerting",
                    "for": "1h",
                    "frequency": "1m",
                    "handler": 1,
                    "name": "Number of trips end by city ID alert",
                    "noDataState": "no_data",
                    "notifications": [
                      {
                        "uid": "QVVrMvj7z"
                      }
                    ]
                  },
           "datasource": null,
           "fieldConfig": {
             "defaults": {
               "color": {
                 "mode": "palette-classic"
               },
               "custom": {
                 "axisLabel": "",
                 "axisPlacement": "auto",
                 "barAlignment": 0,
                 "drawStyle": "line",
                 "fillOpacity": 7,
                 "gradientMode": "opacity",
                 "hideFrom": {
                   "legend": false,
                   "tooltip": false,
                   "viz": false
                 },
                 "lineInterpolation": "smooth",
                 "lineStyle": {
                   "fill": "solid"
                 },
                 "lineWidth": 1,
                 "pointSize": 1,
                 "scaleDistribution": {
                   "type": "linear"
                 },
                 "showPoints": "auto",
                 "spanNulls": false,
                 "stacking": {
                   "group": "A",
                   "mode": "none"
                 },
                 "thresholdsStyle": {
                   "mode": "off"
                 }
               },
               "mappings": [],
               "thresholds": {
                 "mode": "absolute",
                 "steps": [
                   {
                     "color": "green",
                     "value": null
                   },
                   {
                     "color": "red",
                     "value": 80
                   }
                 ]
               }
             },
             "overrides": []
           },
           "gridPos": {
             "h": 9,
             "w": 12,
             "x": 0,
             "y": 9
           },
           "id": 2,
           "interval": null,
           "maxDataPoints": null,
           "options": {
             "legend": {
               "calcs": [
                 "lastNotNull"
               ],
               "displayMode": "list",
               "placement": "bottom"
             },
             "tooltip": {
               "mode": "single"
             }
           },
           "pluginVersion": "8.2.3",
           "targets": [
             {
               "database": "live_business",
               "dateColDataType": "",
               "dateLoading": false,
               "dateTimeColDataType": "time_bucket",
               "dateTimeType": "DATETIME",
               "datetimeLoading": false,
               "extrapolate": true,
               "format": "time_series",
               "formattedQuery": "SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t",
               "interval": "",
               "intervalFactor": 1,
               "query": "SELECT\n    $timeSeries AS t,\n    sum(count) as c,\n    city_id\nFROM $table\n\nWHERE $timeFilter\n\nGROUP BY\n    t,\n    city_id\nORDER BY t ASC\n",
               "refId": "A",
               "round": "0s",
               "skip_comments": true,
               "table": "trips_end_count",
               "tableLoading": false
             }
           ],
           "thresholds": [],
           "timeFrom": null,
           "timeShift": "5m",
           "title": "Number of trips end by city ID",
           "type": "timeseries"
         }
};

local rows = {
  trips: row.new('Trips Health').addPanels([
    panel.fullRow(p)
    for p in [
      panels.allTripsStart,
      panels.tripsStartBy,
      panels.allTripsEnd,
      panels.tripsEndBy,
    ]
  ]),
};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Trips',
  uid='jwebb_trips',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  rows.trips,
])
