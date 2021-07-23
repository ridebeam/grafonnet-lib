local grafana = import '../grafonnet-lib/grafonnet/grafana.libsonnet';
local alertCondition = grafana.alertCondition;

{
  notifications: [
    {
      "uid": "QchRzL3ik" // telegram
    },
    {
      "uid": "XQBRmY3mk" // slack
    },
    {
      "uid": "th3O1VVZk", // opsgenie
    },
  ],

  newCondition(
    threshold,
    thresholdType,
    operatorType = 'and',
    queryRefId = 'A',
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
    )
}
