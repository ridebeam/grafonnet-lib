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

## Active city mapping
Get current active cities by 
1. Use this query to get initial json:
```
with trip as (
  select distinct t.city_id as city_id
  from `ridebeam-data-adhoc.liveescooter.trips` t
  where date(t.created_at) >= date(2022,1,1)
), city as (
  select id, name, parent_region_id
  from `ridebeam-data-adhoc.liveescooter.georegions` g
  where g.type='City'
  and g.enabled=true
  and g.deleted=false
  and g.id in (select city_id from trip)
), data as (
  select city.id, city.name, country.name as country
  from city
  join `ridebeam-data-adhoc.liveescooter.georegions` country on country.id=city.parent_region_id
)
select to_json_string(r)
from (select array(select as struct * from data) as result) r
```

2. extract city name mapping: `jq '.result | to_entries | sort_by(.value.id) | map({(.value.id|tostring):.value.name}) | add' prod-cityId-cityName.json`
3. extract country name mapping: `jq '.result | to_entries | sort_by(.value.id) | map({(.value.id|tostring):.value.country}) | add' prod-cityId-countryName.json`
