#!/usr/bin/env bash

API_TOKEN=$1
JSONNET_PATH=grafonnet-lib
GRAFANA_BASE_URL=http://beam-grafana-prod.ap-southeast-1.elasticbeanstalk.com

generate_dashboard () {
  if [ "${1: -7}" != "jsonnet" ]; then
    return 1
  fi
  jsonnet $1 > dashboard.json
  payload="{\"dashboard\": $(jq . dashboard.json), \"overwrite\": true}"
  echo $payload
  curl -X POST \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "${payload}" \
    "$GRAFANA_BASE_URL/api/dashboards/db"
}

for D in */
do
  # echo $D
  if [[ $D == "dashboards/" ]] ; then
    cd $D
    for F in *
    do
      echo $F
      generate_dashboard $F
    done
    cd -
  fi
done

  # jsonnet dashboard.jsonnet > dashboard.json



# curl -X POST $BASIC_AUTH \
#   -H 'Content-Type: application/json' \
#   -d "${payload}" \
#   "http://admin:admin@localhost:3000/api/dashboards/db"