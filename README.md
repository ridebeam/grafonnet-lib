# grafana-dashboards


## Vehicles counts mapping
For the vehicles counts we need to get the mapping of cityId -> cityName for the dashboard.
1. Get mapping from Redash: https://redash.ridebeam.com/queries/10465
2. Sort the mapping with `jq`: `jq 'to_entries | sort_by(.value) | from_entries' prod-cities.json`