{
  allTripsStartSQL: "SELECT $timeSeries AS t, countMerge(count) as count FROM $table WHERE $timeFilter AND event_name = 'TRIP_START_SUCCESS' GROUP BY t ORDER BY t ASC ",
  allTripsEndSQL: "SELECT $timeSeries AS t, countMerge(count) as count FROM $table WHERE $timeFilter AND event_name = 'TRIP_END_SUCCESS' GROUP BY t ORDER BY t ASC ",
  tripsStartByCitySQL: "SELECT $timeSeries AS t, countMerge(count) as c, city_id FROM $table  WHERE $timeFilter  AND event_name = 'TRIP_START_SUCCESS' GROUP BY t, city_id ORDER BY t ASC ",
  tripsEndByCitySQL: "SELECT $timeSeries AS t, countMerge(count) as c, city_id FROM $table  WHERE $timeFilter  AND event_name = 'TRIP_END_SUCCESS' GROUP BY t, city_id ORDER BY t ASC ",  
  tripsStartByIOTVersionSQL: "SELECT $timeSeries AS t, countMerge(count) as c, iot_version FROM $table  WHERE $timeFilter and event_name = 'TRIP_START_SUCCESS' GROUP BY t, iot_version ORDER BY t ASC ",
  tripsEndByIOTVersionSQL: "SELECT $timeSeries AS t, countMerge(count) as c, iot_version FROM $table  WHERE $timeFilter and event_name = 'TRIP_END_SUCCESS' GROUP BY t, iot_version ORDER BY t ASC ",  
}
