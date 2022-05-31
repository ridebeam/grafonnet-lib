local cities = import '../../data/prod-cities.json';
local vehicleCounts = import 'counts.libsonnet';


vehicleCounts.dashboard('vehicle-counts-prod', cities, 'production')
