local target = import 'gcp-target.libsonnet';
local panel = import 'panel.libsonnet';

local datasources = {
  'vehicles-283509': 'Stackdriver',
  'ridebeam-payments': 'Stackdriver-payments',
  'ridebeam-core': 'Stackdriver-production',
  'ridebeam-core-staging': 'Stackdriver-staging',
};

{

  init(projectName='vehicles-283509'):: {
    target: target.init(projectName),
    panel: panel.init(datasources[projectName]),
  },

}
