local vehicleCounts = import '../vehicle-counts.libsonnet';
local cities = import '../../data/prod-cities.json';


vehicleCounts.dashboard('vehicle-counts-prod', cities, 'production')