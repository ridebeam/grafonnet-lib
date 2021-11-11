local cities = import '../../data/staging-cities.json';
local vehicleCounts = import 'counts.libsonnet';

vehicleCounts.dashboard('vehicle-counts-staging', cities, 'staging')
