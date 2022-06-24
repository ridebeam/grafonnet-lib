{
  tasksCountSQL: '
    WITH DATA AS (
      SELECT time_bucket, countMerge(count) AS count
      FROM $table
      WHERE $timeFilter GROUP BY time_bucket ORDER BY time_bucket ASC
      WITH FILL STEP INTERVAL 1 HOUR
    )
    SELECT $timeSeries, count FROM DATA
  ',
}
