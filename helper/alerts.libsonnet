local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local panel = import './helper/panel.libsonnet';
local alertCondition = grafana.alertCondition;

{
  slack: { uid: 'XQBRmY3mk' },
  slackTest: { uid: '5th60Gc7z' },
  opsgenie: { uid: 'th3O1VVZk' },
  telegram: { uid: 'W8H360mnk' },

  notifications: {
    productionAlerts: [$.slack, $.opsgenie],
    productionWarnings: [$.slack],
    test: [$.slackTest],
  },

  newCondition(
    threshold,
    thresholdType,
    operatorType='and',
    queryRefId='A',
    queryTimeEnd='now',
    queryTimeStart='5m',
    reducerParams=[],
    reducerType='avg',
  ):: alertCondition.new(
    evaluatorParams=[threshold],
    evaluatorType=thresholdType,
    operatorType=operatorType,
    queryRefId=queryRefId,
    queryTimeEnd=queryTimeEnd,
    queryTimeStart=queryTimeStart,
    reducerParams=reducerParams,
    reducerType=reducerType,
  ),
}
