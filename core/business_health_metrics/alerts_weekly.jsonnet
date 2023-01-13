{
  annotations: {
    list: [
      {
        builtIn: 1,
        datasource: {
          type: 'grafana',
          uid: '-- Grafana --',
        },
        enable: true,
        hide: true,
        iconColor: 'rgba(0, 211, 255, 1)',
        name: 'Annotations & Alerts',
        target: {
          limit: 100,
          matchAny: false,
          tags: [],
          type: 'dashboard',
        },
        type: 'dashboard',
      },
    ],
  },
  editable: true,
  fiscalYearStartMonth: 0,
  graphTooltip: 0,
  id: 210,
  links: [],
  liveNow: false,
  panels: [
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: '',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
          unit: 'string',
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'week',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: '#5a5a5a',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'Week',
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'year',
            },
            properties: [
              {
                id: 'displayName',
                value: 'Year',
              },
              {
                id: 'color',
                value: {
                  fixedColor: '#5a5a5a',
                  mode: 'fixed',
                },
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 0,
        y: 0,
      },
      id: 13,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'vertical',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: 'SELECT\n  toISOYear(now()) as year,\n  toISOWeek(now()) as week',
          rawQuery: 'SELECT\n  toISOYear(now()) as year,\n  toISOWeek(now()) as week',
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: '',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'alerts',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'semi-dark-green',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'Alerts',
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 3,
        y: 0,
      },
      id: 6,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(alerts) as alerts\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(alerts) as alerts\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: '',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'false_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'semi-dark-yellow',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'False positives',
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 6,
        y: 0,
      },
      id: 7,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(false_positives) as false_positives\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(false_positives) as false_positives\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: '',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'false_negatives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'semi-dark-red',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'False negatives',
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 9,
        y: 0,
      },
      id: 8,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(false_negatives) as false_negatives\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(false_negatives) as false_negatives\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: 'Out of all the predictions we made, how many are correct?',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
          unit: 'percentunit',
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'accuracy',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: '#529fcc',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'Accuracy',
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 12,
        y: 0,
      },
      id: 11,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    week_alerts AS (\n      SELECT length(timeSlots(toDateTime(toStartOfWeek(now(), 3)), toUInt32(now()-toDateTime(toStartOfWeek(now(), 3))), 1800)) as count\n    ),\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    ((SELECT count from week_alerts) - sum(false_positives))/(SELECT count from week_alerts) as accuracy\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    week_alerts AS (\n      SELECT length(timeSlots(toDateTime(toStartOfWeek(now(), 3)), toUInt32(now()-toDateTime(toStartOfWeek(now(), 3))), 1800)) as count\n    ),\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    ((SELECT count from week_alerts) - sum(false_positives))/(SELECT count from week_alerts) as accuracy\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: 'Out of all alerts that were triggered (positive predictions), how many are correct?',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
          unit: 'percentunit',
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'precision',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'blue',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'Precision',
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 15,
        y: 0,
      },
      id: 9,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(true_positives)/sum(alerts) as precision\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(true_positives)/sum(alerts) as precision\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: 'Out of all anomalies, how many did we alert on?',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
          unit: 'percentunit',
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'recall',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'purple',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'Recall',
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 18,
        y: 0,
      },
      id: 10,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(true_positives)/(sum(true_positives)+sum(false_negatives)) as recall\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(true_positives)/(sum(true_positives)+sum(false_negatives)) as recall\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: '',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
          unit: 'percentunit',
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'f1_score',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: '#242424',
                  mode: 'fixed',
                },
              },
              {
                id: 'displayName',
                value: 'F1 Score',
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 21,
        y: 0,
      },
      id: 12,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'table',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(true_positives)/(sum(true_positives)+((sum(false_positives)+sum(false_negatives))/2)) as f1_score\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    week,\n    sum(true_positives)/(sum(true_positives)+((sum(false_positives)+sum(false_negatives))/2)) as f1_score\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: 'Number of time buckets with multiple alerts (should be 0)',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          displayName: 'Duplicate alerts',
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 1,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'true_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'green',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'yellow',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_negatives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'red',
                  mode: 'fixed',
                },
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 6,
        w: 3,
        x: 0,
        y: 6,
      },
      id: 14,
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'center',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        text: {},
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'time_series',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH alerts as (\nSELECT\n    time_bucket,\n    city_id as georegion_id\nFROM jwebb.alerts_city\nWHERE metric = 'trips'\nUNION ALL\nSELECT\n    time_bucket,\n    country_id as georegion_id\nFROM jwebb.alerts_country\nWHERE metric = 'trips'\nUNION ALL\nSELECT\n    time_bucket,\n    1 as georegion_id\nFROM jwebb.alerts_country\nWHERE metric = 'trips'\n),\nalerts_duplicate as (\nSELECT\n    time_bucket,\n    IF(count() > 1, 1, 0) as has_duplicate\nFROM alerts\nGROUP BY time_bucket, georegion_id\n)\nSELECT\n    toStartOfWeek(time_bucket, 3) as week,\n    sum(has_duplicate) as duplicates\nFROM alerts_duplicate\nGROUP BY week\nORDER BY week",
          rawQuery: "WITH alerts as (\nSELECT\n    time_bucket,\n    city_id as georegion_id\nFROM jwebb.alerts_city\nWHERE metric = 'trips'\nUNION ALL\nSELECT\n    time_bucket,\n    country_id as georegion_id\nFROM jwebb.alerts_country\nWHERE metric = 'trips'\nUNION ALL\nSELECT\n    time_bucket,\n    1 as georegion_id\nFROM jwebb.alerts_country\nWHERE metric = 'trips'\n),\nalerts_duplicate as (\nSELECT\n    time_bucket,\n    IF(count() > 1, 1, 0) as has_duplicate\nFROM alerts\nGROUP BY time_bucket, georegion_id\n)\nSELECT\n    toStartOfWeek(time_bucket, 3) as week,\n    sum(has_duplicate) as duplicates\nFROM alerts_duplicate\nGROUP BY week\nORDER BY week",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      type: 'stat',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: 'Global + countries + cities',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'palette-classic',
          },
          custom: {
            axisLabel: '',
            axisPlacement: 'auto',
            barAlignment: 0,
            drawStyle: 'bars',
            fillOpacity: 100,
            gradientMode: 'none',
            hideFrom: {
              legend: false,
              tooltip: false,
              viz: false,
            },
            lineInterpolation: 'linear',
            lineWidth: 0,
            pointSize: 1,
            scaleDistribution: {
              type: 'linear',
            },
            showPoints: 'auto',
            spanNulls: false,
            stacking: {
              group: 'A',
              mode: 'normal',
            },
            thresholdsStyle: {
              mode: 'off',
            },
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'true_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'green',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'yellow',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_negatives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'red',
                  mode: 'fixed',
                },
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 7,
        w: 24,
        x: 0,
        y: 12,
      },
      id: 2,
      options: {
        legend: {
          calcs: [],
          displayMode: 'list',
          placement: 'bottom',
        },
        tooltip: {
          mode: 'multi',
          sort: 'none',
        },
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'time_series',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            'global' as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_global\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    country AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('country:', toString(country_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_country\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    city AS\n    (\n        SELECT\n            toStartOfWeek(time_bucket, 3) AS week,\n            concat('city:', toString(city_id)) as id,\n            countIf(false_negative = 0) AS alerts,\n            countIf(false_positive = 1) AS false_positives,\n            countIf(false_negative = 1) AS false_negatives,\n            alerts-false_positives as true_positives\n        FROM jwebb.alerts_city\n        WHERE metric = 'trips'\n        GROUP BY\n            week, id\n    ),\n    unioned as (\n        SELECT * FROM city\n        UNION ALL\n        SELECT * FROM country\n        UNION ALL\n        SELECT * FROM global\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM unioned\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      title: 'Overall alerts',
      type: 'timeseries',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: 'Global + countries + cities',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'palette-classic',
          },
          custom: {
            axisLabel: '',
            axisPlacement: 'auto',
            barAlignment: 0,
            drawStyle: 'bars',
            fillOpacity: 100,
            gradientMode: 'none',
            hideFrom: {
              legend: false,
              tooltip: false,
              viz: false,
            },
            lineInterpolation: 'linear',
            lineWidth: 0,
            pointSize: 1,
            scaleDistribution: {
              type: 'linear',
            },
            showPoints: 'auto',
            spanNulls: false,
            stacking: {
              group: 'A',
              mode: 'normal',
            },
            thresholdsStyle: {
              mode: 'off',
            },
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'true_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'green',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'yellow',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_negatives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'red',
                  mode: 'fixed',
                },
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 8,
        w: 24,
        x: 0,
        y: 19,
      },
      id: 3,
      options: {
        legend: {
          calcs: [],
          displayMode: 'list',
          placement: 'bottom',
        },
        tooltip: {
          mode: 'multi',
          sort: 'none',
        },
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'time_series',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    global_alerts AS\n    (\n      SELECT\n          toStartOfWeek(time_bucket, 3) AS week,\n          'global' as id,\n          countIf(false_negative = 0) AS alerts,\n          countIf(false_positive = 1) AS false_positives,\n          countIf(false_negative = 1) AS false_negatives,\n          alerts-false_positives as true_positives\n      FROM jwebb.alerts_global\n      WHERE metric = 'trips'\n      GROUP BY\n          week, id\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM global_alerts\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    global_alerts AS\n    (\n      SELECT\n          toStartOfWeek(time_bucket, 3) AS week,\n          'global' as id,\n          countIf(false_negative = 0) AS alerts,\n          countIf(false_positive = 1) AS false_positives,\n          countIf(false_negative = 1) AS false_negatives,\n          alerts-false_positives as true_positives\n      FROM jwebb.alerts_global\n      WHERE metric = 'trips'\n      GROUP BY\n          week, id\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM global_alerts\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      title: 'Global alerts',
      type: 'timeseries',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: '',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'palette-classic',
          },
          custom: {
            axisLabel: '',
            axisPlacement: 'auto',
            barAlignment: 0,
            drawStyle: 'bars',
            fillOpacity: 100,
            gradientMode: 'none',
            hideFrom: {
              legend: false,
              tooltip: false,
              viz: false,
            },
            lineInterpolation: 'linear',
            lineWidth: 0,
            pointSize: 1,
            scaleDistribution: {
              type: 'linear',
            },
            showPoints: 'auto',
            spanNulls: false,
            stacking: {
              group: 'A',
              mode: 'normal',
            },
            thresholdsStyle: {
              mode: 'off',
            },
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'true_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'green',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'yellow',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_negatives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'red',
                  mode: 'fixed',
                },
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 8,
        w: 24,
        x: 0,
        y: 27,
      },
      id: 4,
      options: {
        legend: {
          calcs: [],
          displayMode: 'list',
          placement: 'bottom',
        },
        tooltip: {
          mode: 'multi',
          sort: 'none',
        },
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'time_series',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    country_alerts AS\n    (\n      SELECT\n          toStartOfWeek(time_bucket, 3) AS week,\n          country_id,\n          countIf(false_negative = 0) AS alerts,\n          countIf(false_positive = 1) AS false_positives,\n          countIf(false_negative = 1) AS false_negatives,\n          alerts-false_positives as true_positives\n      FROM jwebb.alerts_country\n      WHERE metric = 'trips'\n      GROUP BY\n          week, country_id\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM country_alerts\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    country_alerts AS\n    (\n      SELECT\n          toStartOfWeek(time_bucket, 3) AS week,\n          country_id,\n          countIf(false_negative = 0) AS alerts,\n          countIf(false_positive = 1) AS false_positives,\n          countIf(false_negative = 1) AS false_negatives,\n          alerts-false_positives as true_positives\n      FROM jwebb.alerts_country\n      WHERE metric = 'trips'\n      GROUP BY\n          week, country_id\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM country_alerts\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      title: 'Country alerts',
      type: 'timeseries',
    },
    {
      datasource: {
        type: 'vertamedia-clickhouse-datasource',
        uid: '_Az-rRXnz',
      },
      description: '',
      fieldConfig: {
        defaults: {
          color: {
            mode: 'palette-classic',
          },
          custom: {
            axisLabel: '',
            axisPlacement: 'auto',
            barAlignment: 0,
            drawStyle: 'bars',
            fillOpacity: 100,
            gradientMode: 'none',
            hideFrom: {
              legend: false,
              tooltip: false,
              viz: false,
            },
            lineInterpolation: 'linear',
            lineWidth: 0,
            pointSize: 1,
            scaleDistribution: {
              type: 'linear',
            },
            showPoints: 'auto',
            spanNulls: false,
            stacking: {
              group: 'A',
              mode: 'normal',
            },
            thresholdsStyle: {
              mode: 'off',
            },
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
        },
        overrides: [
          {
            matcher: {
              id: 'byName',
              options: 'true_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'green',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_positives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'yellow',
                  mode: 'fixed',
                },
              },
            ],
          },
          {
            matcher: {
              id: 'byName',
              options: 'false_negatives',
            },
            properties: [
              {
                id: 'color',
                value: {
                  fixedColor: 'red',
                  mode: 'fixed',
                },
              },
            ],
          },
        ],
      },
      gridPos: {
        h: 8,
        w: 24,
        x: 0,
        y: 35,
      },
      id: 5,
      options: {
        legend: {
          calcs: [],
          displayMode: 'list',
          placement: 'bottom',
        },
        tooltip: {
          mode: 'multi',
          sort: 'none',
        },
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          database: 'jwebb',
          datasource: {
            type: 'vertamedia-clickhouse-datasource',
            uid: '_Az-rRXnz',
          },
          dateTimeColDataType: 'time_bucket',
          dateTimeType: 'DATETIME',
          datetimeLoading: false,
          extrapolate: true,
          format: 'time_series',
          formattedQuery: 'SELECT $timeSeries as t, count() FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
          intervalFactor: 1,
          query: "WITH\n    city_alerts AS\n    (\n      SELECT\n          toStartOfWeek(time_bucket, 3) AS week,\n          city_id,\n          countIf(false_negative = 0) AS alerts,\n          countIf(false_positive = 1) AS false_positives,\n          countIf(false_negative = 1) AS false_negatives,\n          alerts-false_positives as true_positives\n      FROM jwebb.alerts_city\n      WHERE metric = 'trips'\n      GROUP BY\n          week, city_id\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM city_alerts\nGROUP BY week\nORDER BY week ASC",
          rawQuery: "WITH\n    city_alerts AS\n    (\n      SELECT\n          toStartOfWeek(time_bucket, 3) AS week,\n          city_id,\n          countIf(false_negative = 0) AS alerts,\n          countIf(false_positive = 1) AS false_positives,\n          countIf(false_negative = 1) AS false_negatives,\n          alerts-false_positives as true_positives\n      FROM jwebb.alerts_city\n      WHERE metric = 'trips'\n      GROUP BY\n          week, city_id\n    )\nSELECT\n    toUInt32(toDateTime(week)) * 1000 as week,\n    sum(true_positives) as true_positives,\n    sum(false_positives) as false_positives,\n    sum(false_negatives) as false_negatives\nFROM city_alerts\nGROUP BY week\nORDER BY week ASC",
          refId: 'A',
          round: '0s',
          skip_comments: true,
        },
      ],
      title: 'City alerts',
      type: 'timeseries',
    },
  ],
  refresh: '',
  schemaVersion: 36,
  style: 'dark',
  tags: [],
  templating: {
    list: [],
  },
  time: {
    from: 'now-30d',
    to: 'now',
  },
  timepicker: {},
  timezone: '',
  title: 'Alerts weekly overview',
  uid: 'business_health_metrics_alerts_weekly',
  version: 26,
  weekStart: '',
}
