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
  id: null,
  iteration: 1673580131175,
  links: [],
  liveNow: false,
  panels: [
    {
      collapsed: false,
      datasource: {
        type: 'prometheus',
        uid: 'fdLlh8Hnk',
      },
      gridPos: {
        h: 1,
        w: 24,
        x: 0,
        y: 0,
      },
      id: 4,
      panels: [],
      title: 'Workflow Execution',
      type: 'row',
    },
    {
      datasource: {
        type: 'prometheus',
        uid: 'fdLlh8Hnk',
      },
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
            ],
          },
        },
        overrides: [],
      },
      gridPos: {
        h: 7,
        w: 12,
        x: 0,
        y: 1,
      },
      id: 2,
      links: [],
      options: {
        colorMode: 'value',
        graphMode: 'none',
        justifyMode: 'auto',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          datasource: {
            type: 'prometheus',
            uid: 'fdLlh8Hnk',
          },
          expr: 'sum(increase(argo_workflows_task_exec_result{cluster="$cluster", status="Succeeded"}[$__range])) by (task_name)',
          format: 'time_series',
          intervalFactor: 1,
          legendFormat: '{{task_name}}',
          refId: 'A',
        },
      ],
      title: 'Task Execution Success Count',
      type: 'stat',
    },
    {
      datasource: {
        type: 'prometheus',
        uid: 'fdLlh8Hnk',
      },
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
                color: 'super-light-yellow',
                value: 1,
              },
              {
                color: 'light-yellow',
                value: 2,
              },
              {
                color: '#EAB839',
                value: 3,
              },
              {
                color: 'semi-dark-orange',
                value: 5,
              },
              {
                color: 'red',
                value: 8,
              },
              {
                color: 'semi-dark-red',
                value: 10,
              },
            ],
          },
        },
        overrides: [],
      },
      gridPos: {
        h: 7,
        w: 12,
        x: 12,
        y: 1,
      },
      id: 3,
      links: [],
      options: {
        colorMode: 'value',
        graphMode: 'none',
        justifyMode: 'auto',
        orientation: 'auto',
        reduceOptions: {
          calcs: [
            'lastNotNull',
          ],
          fields: '',
          values: false,
        },
        textMode: 'auto',
      },
      pluginVersion: '8.5.6',
      targets: [
        {
          datasource: {
            type: 'prometheus',
            uid: 'fdLlh8Hnk',
          },
          expr: 'sum(increase(argo_workflows_task_exec_result{cluster="$cluster", status="Failed"}[$__range])) by (task_name)',
          format: 'time_series',
          intervalFactor: 1,
          legendFormat: '{{task_name}}',
          refId: 'A',
        },
      ],
      title: 'Task Execution Fail Count',
      type: 'stat',
    },
  ],
  refresh: '30s',
  schemaVersion: 36,
  style: 'dark',
  tags: [
    'generated',
  ],
  templating: {
    list: [
      {
        current: {
          text: 'core-sg',
          value: 'core-sg',
        },
        hide: 0,
        includeAll: false,
        label: '',
        multi: false,
        name: 'cluster',
        options: [
          {
            selected: false,
            text: 'staging-sg',
            value: 'staging-sg',
          },
          {
            selected: true,
            text: 'core-sg',
            value: 'core-sg',
          },
        ],
        query: 'staging-sg,core-sg',
        refresh: 0,
        skipUrlSync: false,
        type: 'custom',
      },
    ],
  },
  time: {
    from: 'now-24h',
    to: 'now-1m',
  },
  timepicker: {
    nowDelay: '1m',
    refresh_intervals: [
      '5s',
      '10s',
      '30s',
      '1m',
      '5m',
      '15m',
      '30m',
      '1h',
      '2h',
      '1d',
    ],
    time_options: [
      '5m',
      '15m',
      '1h',
      '6h',
      '12h',
      '24h',
      '2d',
      '7d',
      '30d',
    ],
  },
  timezone: 'browser',
  title: 'Tasks Overview',
  uid: 'workflows_tasks_overview',
  version: 2,
  weekStart: '',
}
