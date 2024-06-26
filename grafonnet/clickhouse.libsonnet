{
  /**
   * Creates an clickhouse SQL target.
   *
   * @name clickhouse.target
   *
   * @param database specify the database
   * @param table specify the table
   * @param query The SQL query
   * @param format (default `'time_series'`)
   * @param dateTimeColDataType (default `'time_bucket'`)
   */

  target(
    database,
    datasourceUID,
    table,
    query,
    format='time_series',
    dateTimeColDataType='time_bucket',
    interval=null,
  ):: {
    database: database,
    datasource: {
      type: 'vertamedia-clickhouse-datasource',
      uid: datasourceUID,
    },
    dateLoading: false,
    dateTimeColDataType: dateTimeColDataType,
    datetimeLoading: false,
    extrapolate: true,
    table: table,
    tableLoading: false,
    skip_comments: true,
    refId: 'A',
    round: '0s',
    format: format,
    intervalFactor: 1,
    [if interval != null then 'interval']: interval,
    dateTimeType: 'DATETIME',
    query: query,
    formattedQuery: query,
    rawQuery: false,
  },
}
