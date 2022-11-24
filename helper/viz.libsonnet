{
  fieldOverride(name, properties):: {
    matcher: {
      id: 'byName',
      options: name,
    },
    properties: std.map(function(p) {
                  id: 'custom.%s' % [p],
                  value: properties.custom[p],
                }, std.objectFields(std.get(properties, 'custom', {})))
                + std.map(function(p) {
                  id: p,
                  value: properties[p],
                }, std.filter(function(p) p != 'custom', std.objectFields(properties))),
  },
}
