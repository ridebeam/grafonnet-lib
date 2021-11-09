#!/usr/bin/env bash
set -e

API_TOKEN=$1
JSONNET_PATH=grafonnet-lib
GRAFANA_BASE_URL=https://grafana.devops.ridebeam.cloud
FILTER=${2:-'dashboards/*/'}

generate_dashboard() {
  echo " ------ "
  echo "generating dashboard '$1'"

  filename=$(basename $1)
  filename="${filename%.*}"
  dashboardUID="$4_$(basename $filename)"

  tmpJson=$(mktemp /tmp/gen-dashboard.XXXXXX)
  jsonnet "$1" | jq ".uid=\"$dashboardUID\"" >"$tmpJson"

  # run create for alerts first without overwrite as alerts only initialized on update
  if [[ $3 == "alerts" ]]; then
    tmpCreateDashboard=$(mktemp /tmp/gen-dashboard-create.XXXXXX)
    jq "{dashboard: ., folderId: ${2:-0} }" "$tmpJson" >"$tmpCreateDashboard"
    curl \
      -H "Authorization: Bearer $API_TOKEN" \
      -H 'Content-Type: application/json' \
      --data @"${tmpCreateDashboard}" \
      "$GRAFANA_BASE_URL/api/dashboards/db"
    echo ""
  fi

  tmpUpdateDashboard=$(mktemp /tmp/gen-dashboard-update.XXXXXX)
  jq "{dashboard: ., folderId: ${2:-0}, overwrite: true }" "$tmpJson" >"$tmpUpdateDashboard"
  curl --fail \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data @"${tmpUpdateDashboard}" \
    "$GRAFANA_BASE_URL/api/dashboards/db"
  echo ""
}

for D in $FILTER; do
  basename=$(basename "$D")

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

  folderUID=$(cat $tmpFolder | jq '.uid' -r)
  folderID=$(curl -s --fail -X PUT \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data @"${tmpFolder}" \
    "$GRAFANA_BASE_URL/api/folders/$folderUID" |
    jq '.id')
  echo ""

  # now we can upload dashboards
  for F in "${D}"*.jsonnet; do
    if [[ $F != "${D}folder.jsonnet" ]]; then
      generate_dashboard "$F" "$folderID" "$basename" "$folderUID"
    fi
  done
done
