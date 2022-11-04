#!/usr/bin/env bash
set -e

JSONNET_PATH=grafonnet-lib

generate_dashboard() {
  echo " ------ "
  echo "generating $1"

  jsonnet "$1" > /dev/null
}

for D in devops/*/; do
  basename=$(basename "$D")

  for F in "${D}"*.jsonnet; do
    if [[ $F != "${D}folder.jsonnet" ]]; then
      generate_dashboard "$F"
    fi
  done
done

#for D in core/*/; do
#  basename=$(basename "$D")
#
#  for F in "${D}"*.jsonnet; do
#    if [[ $F != "${D}folder.jsonnet" ]]; then
#      generate_dashboard "$F"
#    fi
#  done
#done
