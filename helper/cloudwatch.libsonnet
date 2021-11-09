local panel = import 'panel.libsonnet';

{

  init():: {
    panel: panel.init('CloudWatch'),
  },

}
