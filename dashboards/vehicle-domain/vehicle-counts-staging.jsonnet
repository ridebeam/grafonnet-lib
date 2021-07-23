local vehicleCounts = import '../vehicle-counts.libsonnet';
local cities = import '../../data/staging-cities.json';


vehicleCounts.dashboard('vehicle-counts-staging-test',cities, 'staging')
