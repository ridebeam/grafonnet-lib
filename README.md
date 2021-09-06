# Grafana Dashboards

## Setup

Install [jsonnet](https://jsonnet.org/).

Install jq `brew install jq`

Instructions can be found [here](https://github.com/google/jsonnet#packages).

Clone the [Beam Grafonnet Submodule](https://github.com/ridebeam/grafonnet-lib).

Copy the library over to the root of the directory to run locally.

## Data sources and Projects

Metrics belong to different projects on GCP. Grafana requires a data source that has access 
to the relevant project your service is deployed in.

When generating dashboards you need to let grafana what project to look for metrics in
and what data source has access to it.

**Project / Data source**

Vehicles (legacy) - vehicles-283509 / Stackdriver

Production - ridebeam-core / Stackdriver-production

Staging - ridebeam-core-staging / Stackdriver-staging

Payments (has its own for PCI compliance) - ridebeam-payments / Stackdriver-payments

## Generate JSON using CLI to create a dashboard

Run the command and copy the JSON response
```
jsonnet --ext-str DATASOURCE={relevant data source} --ext-str PROJECT_NAME={relevant gcp project} -J grafonnet-lib ${jsonnet file} | pbcopy
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
