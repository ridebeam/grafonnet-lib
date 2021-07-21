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

Go to beam grafana and import a new dashboard using the JSON above

For alerts, dashboard will need to be saved manually using this method as alerts are only initialized on update

## Run update.sh script to generate folders and dashboard

***Important*** - will overwrite current dashboards, prefer to create and run own script
```
sh update.sh
```
