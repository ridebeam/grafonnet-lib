# Grafana Dashboards

## Setup

Install [jsonnet](https://jsonnet.org/).

Instructions can be found [here](https://github.com/google/jsonnet#packages).

Clone the [Beam Grafonnet Submodule](https://github.com/ridebeam/grafonnet-lib).

Copy the library over to the root of the directory to run locally.

## Generate JSON using CLI to create a dashboard

Run the command and copy the JSON response
```
jsonnet -J grafonnet-lib ${jsonnet file} | pbcopy
```

Go to beam grafana and import a new dashboard using the JSON above

For alerts, dashboard will need to be saved manually using this method as alerts are only initialized on update

## Run update.sh script to generate folders and dashboard

***Important*** - will overwrite current dashboards, prefer to create and run own script
```
sh update.sh
```

## Vehicles counts mapping
For the vehicles counts we need to get the mapping of cityId -> cityName for the dashboard.
1. Get mapping from Redash: https://redash.ridebeam.com/queries/10465
2. Sort the mapping with `jq`: `jq 'to_entries | sort_by(.value) | from_entries' prod-cities.json`
