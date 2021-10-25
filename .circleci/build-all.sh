#!/usr/bin/env bash
set -e

JSONNET_PATH=grafonnet-lib

generate_dashboard() {
  echo " ------ "
  echo "generating $1"

  jsonnet "$1" > /dev/null
}

for D in dashboards/*/; do
  basename=$(basename "$D")

  for F in "${D}"*.jsonnet; do
    if [[ $F != "${D}folder.jsonnet" ]]; then
      generate_dashboard "$F"
    fi
  done
done
