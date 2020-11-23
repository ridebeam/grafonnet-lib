// local grafana = import 'grafonnet/grafana.libsonnet';
// local row = grafana.row;
// local graphPanel = grafana.graphPanel;
// local cloudwatch = grafana.cloudwatch;
// local stackdriver = grafana.stackdriver;
// local template = grafana.template;
// local alertCondition = grafana.alertCondition;

// local helpers = import 'helpers.jsonnet';


// local notifications = [
//   {
//     "uid": "XQBRmY3mk"
//   },
//   {
//     "uid": "th3O1VVZk"
//   }
// ];

  // .addPanel(
  //   helpers.addStackdriverGauge()
  //     .addAlert('new alert', notifications=helpers.notifications)
  //     .addConditions([alertCondition.new(evaluatorParams=[500])])
  //   , gridPos={
  //     x: 0,
  //     y: 0,
  //     w: 8,
  //     h: 12,
  //   }
  // )

  // .addPanel(
  //   helpers.addStackdriverGauge()
  //     .addAlert('new alert', notifications=helpers.notifications)
  //     .addConditions([alertCondition.new(evaluatorParams=[500])])
  //   , gridPos={
  //     x: 12,
  //     y: 0,
  //     w: 8,
  //     h: 12,
  //   }
  // )