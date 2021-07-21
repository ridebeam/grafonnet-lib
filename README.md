# Grafana Dashboards

## Setup

Install jsonnet cli

Clone beam grafonnet library here: https://github.com/ridebeam/grafonnet-lib

Copy the library over to the root of the directory.

## Generate JSON using CLI to create a dashboard

Run the command and copy the JSON response
```
jsonnet -J grafonnet-lib ${jsonnet file} | pbcopy
```

Go to beam grafana and import a new dashboard using the JSON above.
