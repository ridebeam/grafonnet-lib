#!/usr/bin/env bash

API_TOKEN=$1
JSONNET_PATH=grafonnet-lib
GRAFANA_BASE_URL=http://beam-grafana-prod.ap-southeast-1.elasticbeanstalk.com

generate_dashboard () {
  echo " ------ "
  echo "generating dashboard $1"

  payload="{\"dashboard\": $(jsonnet "$1"), \"overwrite\": true, \"folderId\": ${2:-0} }"
  curl \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "${payload}" \
    "$GRAFANA_BASE_URL/api/dashboards/db" || exit 1
  echo ""
}

for F in dashboards/*.jsonnet; do
  generate_dashboard $F
done

for D in dashboards/*/; do

  # make sure folders exist, before uploading dashboards
  F=${D}folder.jsonnet
  echo " ------ "
  echo "preparing folder $D"

  # PUT only allows to update, so we create and update, to ensure changes apply
  curl -s \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$(jsonnet $F)" \
    "$GRAFANA_BASE_URL/api/folders"
  echo ""

  ID=$(curl -s -X PUT \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$(jsonnet $F)" \
    "$GRAFANA_BASE_URL/api/folders/$(jsonnet $F | jq '.uid' -r)" \
     | jq '.id') || exit 1
  echo ""

  # now we can upload dashboards
  for F in "${D}"*.jsonnet; do
    if [[ $F != "${D}folder.jsonnet" ]]; then
      generate_dashboard "$F" "$ID"
    fi
  done
done