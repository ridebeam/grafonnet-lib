local vehicleCounts = import '../../helper/vehicle-counts.libsonnet';
local cities = import '../../data/prod-cities.json';


vehicleCounts.dashboard('vehicle-counts-prod', cities, 'production')