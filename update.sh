#!/usr/bin/env bash
set -e

API_TOKEN=$1
JSONNET_PATH=grafonnet-lib
GRAFANA_BASE_URL=http://beam-grafana-prod.ap-southeast-1.elasticbeanstalk.com
PROJECT_NAME=vehicles-283509
DATASOURCE=Stackdriver

generate_dashboard() {
  echo " ------ "
  echo "generating dashboard $1 for $PROJECT_NAME"

  tmpJson=$(mktemp /tmp/gen-dashboard.XXXXXX)
  jsonnet "$1" --ext-str PROJECT_NAME=$PROJECT_NAME --ext-str DATASOURCE=$DATASOURCE > "$tmpJson"

  # run create for alerts first without overwrite as alerts only initialized on update
  if [[ $3 == "alerts" ]]; then
    tmpCreateDashboard=$(mktemp /tmp/gen-dashboard-create.XXXXXX)
    jq "{dashboard: ., folderId: ${2:-0} }" "$tmpJson" > "$tmpCreateDashboard"
    curl \
      -H "Authorization: Bearer $API_TOKEN" \
      -H 'Content-Type: application/json' \
      --data @"${tmpCreateDashboard}" \
      "$GRAFANA_BASE_URL/api/dashboards/db"
    echo ""
  fi

  tmpUpdateDashboard=$(mktemp /tmp/gen-dashboard-update.XXXXXX)
  jq "{dashboard: ., folderId: ${2:-0}, overwrite: true }" "$tmpJson" > "$tmpUpdateDashboard"
  curl --fail \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data @"${tmpUpdateDashboard}" \
    "$GRAFANA_BASE_URL/api/dashboards/db"
  echo ""
}

for D in dashboards/*/; do
  basename=$(basename "$D")

  PROJECT_NAME=vehicles-283509
  DATASOURCE=Stackdriver
  if [[ -f "${D}args.env" ]]; then
    source "${D}args.env"
  fi

  # make sure folders exist, before uploading dashboards
  F=${D}folder.jsonnet
  echo " ------ "
  echo "preparing folder $D"

  tmpFolder=$(mktemp /tmp/gen-dashboard-folder.XXXXXX)
  jsonnet "$F" >"${tmpFolder}"

  # PUT only allows to update, so we create and update, to ensure changes apply
  curl -s \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data @"${tmpFolder}" \
    "$GRAFANA_BASE_URL/api/folders"
  echo ""

  ID=$(curl -s --fail -X PUT \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data @"${tmpFolder}" \
    "$GRAFANA_BASE_URL/api/folders/$(cat $tmpFolder | jq '.uid' -r)" |
    jq '.id')
  echo ""

  # now we can upload dashboards
  for F in "${D}"*.jsonnet; do
    if [[ $F != "${D}folder.jsonnet" ]]; then
      generate_dashboard "$F" "$ID" "$basename"
    fi
  done
done
