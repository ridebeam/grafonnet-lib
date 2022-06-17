{
  allTripsSQL: 'SELECT $timeSeries AS t, sum(count) as count FROM $table WHERE $timeFilter GROUP BY t ORDER BY t ASC ',
  tripsByCitySQL: 'SELECT $timeSeries AS t, sum(count) as c, city_id FROM $table  WHERE $timeFilter  GROUP BY t, city_id ORDER BY t ASC ',
}
