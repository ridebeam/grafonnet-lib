local vehicleCounts = import '../../helper/vehicle-counts.libsonnet';
local cities = import '../../data/staging-cities.json';


vehicleCounts.dashboard('vehicle-counts-staging',cities, 'staging')
