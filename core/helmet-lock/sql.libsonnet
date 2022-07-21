{
  tasksCountSQL: 'SELECT $timeSeries as t, max(count) FROM $table WHERE $timeFilter GROUP BY t ORDER BY t',
}
