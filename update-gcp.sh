#!/usr/bin/env bash
set -e

INPUT=$1
GRAFANA_BASE_URL=$2
API_TOKEN=$3
JSONNET_PATH=grafonnet-lib

generate_dashboard() {
  local GRAFANA_BASE_URL=$5
  local API_TOKEN=$6
  echo "generating dashboard '$1'"

  filename=$(basename $1)
  filename="${filename%.*}"
  dashboardUID="$4_$(basename $filename)"

  tmpJson=$(mktemp /tmp/gen-dashboard.XXXXXX)
  jsonnet "$1" | jq ".uid=\"$dashboardUID\"" >"$tmpJson"

  tmpUpdateDashboard=$(mktemp /tmp/gen-dashboard-update.XXXXXX)
  jq "{dashboard: ., folderId: ${2:-0}, overwrite: true }" "$tmpJson" >"$tmpUpdateDashboard"
  curl --fail -k \
    -H "Authorization: Bearer $API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data @"${tmpUpdateDashboard}" \
    "$GRAFANA_BASE_URL/api/dashboards/db"
  echo ""
}

generate_grafana() {
  local INPUT=$1
  local GRAFANA_BASE_URL=$2
  local API_TOKEN=$3
  for D in $(find $1 -mindepth 1 -maxdepth 1 -type d); do
    folderUID=$(basename "$D")

    # make sure folders exist, before uploading dashboards
    F=${D}/folder.jsonnet
    echo " ------ "
    echo "preparing folder $D (UID: $folderUID)"

    tmpFolder=$(mktemp /tmp/gen-dashboard-folder.XXXXXX)
    jsonnet "$F" | jq ".uid=\"$folderUID\"" > "${tmpFolder}"

    # PUT only allows to update, so we create and update, to ensure changes apply
    curl -s -k \
      -H "Authorization: Bearer $API_TOKEN" \
      -H 'Content-Type: application/json' \
      --data @"${tmpFolder}" \
      "$GRAFANA_BASE_URL/api/folders"
    echo ""

    folderID=$(curl -s --fail -k -X PUT \
      -H "Authorization: Bearer $API_TOKEN" \
      -H 'Content-Type: application/json' \
      --data @"${tmpFolder}" \
      "$GRAFANA_BASE_URL/api/folders/$folderUID" |
      jq '.id')
    echo ""

    # now we can upload dashboards
    for F in "${D}"/*.jsonnet; do
      if [[ $F != "${D}/folder.jsonnet" ]]; then
        generate_dashboard "$F" "$folderID" "$basename" "$folderUID" "$GRAFANA_BASE_URL" "$API_TOKEN"
      fi
    done
  done
}

generate_grafana $INPUT $GRAFANA_BASE_URL $API_TOKEN
