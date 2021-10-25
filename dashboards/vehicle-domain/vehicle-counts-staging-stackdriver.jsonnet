local cities = import '../../data/staging-cities.json';
local vehicleCounts = import 'vehicle-counts-stackdriver.libsonnet';


vehicleCounts.dashboard('vehicle-counts-staging', cities, 'staging')
