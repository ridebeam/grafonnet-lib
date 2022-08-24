local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local cloudwatch = grafana.cloudwatch;
local template = grafana.template;
local row = grafana.row;
local clickhouse = import '../../helper/clickhouse.libsonnet';
local sql = import './sql.libsonnet';

local helpers = clickhouse.init();
local target = helpers.target;
local panel = helpers.panel;

local targets = {
  tasksCount: target.target(
    database='jwebb',
    datasourceUID=clickhouse.dataSourceUIDProd,
    query=sql.tasksCountSQL,
    table='helmet_lock_tasks_count_v',
  ),
};

local alertConditions = {
  tasksCount: {
    evaluator: {
      params: [
        1
      ],
      type: 'lt'
    },
    operator: {
      type: 'and'
    },
    query: {
      params: [
        'A',
        '24h',
        'now'
      ]
    },
    reducer: {
      params: [],
      type: 'avg'
    },
    type: 'query',
  },    
};

local panels = {
  tasksCount: panel.new(title='Number of helmet lock tasks created', time_shift='1h')
    .addTargets([targets.tasksCount])
    .addAlert(
      name='Number of helmet lock tasks created alert',
      message='No helmet lock tasks created for a day ',
      notifications=[{ uid: 'QVVrMvj7z' }],
    )
    .addConditions([alertConditions.tasksCount]),
};

local rows = {
  tasks: row.new('Tasks').addPanels([
    panel.fullRow(p)
    for p in [
      panels.tasksCount,
    ]
  ]),
};


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'JWebb Helmet Lock',
  uid='jwebb_helmet_lock',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)

.addRows([
  rows.tasks,
])
