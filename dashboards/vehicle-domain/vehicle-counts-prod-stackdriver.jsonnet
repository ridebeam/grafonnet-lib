local cities = import '../../data/prod-cities.json';
local vehicleCounts = import 'vehicle-counts-stackdriver.libsonnet';


vehicleCounts.dashboard('vehicle-counts-prod', cities, 'production')
