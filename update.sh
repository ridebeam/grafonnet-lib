#!/usr/bin/env bash
set -x

API_TOKEN=$1
JSONNET_PATH=grafonnet-lib
GRAFANA_BASE_URL=http://beam-grafana-prod.ap-southeast-1.elasticbeanstalk.com

generate_dashboard () {
  if [ "${1: -7}" != "jsonnet" ]; then
    return 1
  fi
  payload="{\"dashboard\": $(jsonnet $1), \"overwrite\": true}"
  echo $payload
  curl -X POST --fail \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "${payload}" \
    "$GRAFANA_BASE_URL/api/dashboards/db" || exit 1
}

for D in */
do
  if [[ $D == "dashboards/" ]] ; then
    for F in $D*.jsonnet
    do
      echo $F
      generate_dashboard $F
    done
  fi
done