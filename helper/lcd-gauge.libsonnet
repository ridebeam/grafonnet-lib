{
  new(
    key=key,
    value=value,
    unit=null,
    desc=true,
    color='green',
  ):: {
    styles: null, // must be null, hack for grafannet to use new table instead of table-old
    type: 'table',
    transformations: [
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
          },
          indexByName: {},
          renameByName: {
            Value: value,
          },
        },
      },
    ],
    fieldConfig: {
      defaults: {
        custom: {
          align: 'left',
          displayMode: 'auto',
        },
        unit: unit,
      },
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: value,
          },
          properties: [
            {
              id: 'custom.displayMode',
              value: 'lcd-gauge',
            },
            {
              id: 'thresholds',
              value: {
                mode: 'absolute',
                steps: [
                  {
                    color: color,
                    value: null,
                  },
                ],
              },
            },
          ],
        },
        {
          matcher: {
            id: 'byType',
            options: 'string',
          },
          properties: [
            {
              id: 'custom.width',
              value: 150,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: key,
          },
          properties: [
            {
              id: 'custom.width',
              value: 300,
            },
          ],
        },
      ],
    },
    options: {
      showHeader: true,
      sortBy: [
        {
          desc: desc,
          displayName: value,
        },
      ],
    },
  },
}
