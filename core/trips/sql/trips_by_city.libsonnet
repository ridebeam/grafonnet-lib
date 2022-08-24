{
  trips_start_threshold_a: |||
    SELECT
        $timeSeries as t,
        max(count),
        max(median_wow)
    FROM $table

    WHERE
        $timeFilter
        AND event_name = 'TRIP_START_SUCCESS'
        AND city_id = $city_id
    GROUP BY
        t,
        city_id
    ORDER BY t
  |||,
  trips_start_threshold_b: |||
    SELECT
        $timeSeries as t,
        max(count - threshold_1Z)
    FROM $table

    WHERE
        $timeFilter
        AND event_name = 'TRIP_START_SUCCESS'
        AND city_id = $city_id
    GROUP BY
        t,
        city_id
    ORDER BY t
  |||,
  trips_end_threshold_a: |||
    SELECT
        $timeSeries as t,
        max(count),
        max(median_wow)
    FROM $table

    WHERE
        $timeFilter
        AND event_name = 'TRIP_END_SUCCESS'
        AND city_id = $city_id
    GROUP BY
        t,
        city_id
    ORDER BY t
  |||,
  trips_end_threshold_b: |||
    SELECT
        $timeSeries as t,
        max(count - threshold_1Z)
    FROM $table

    WHERE
        $timeFilter
        AND event_name = 'TRIP_END_SUCCESS'
        AND city_id = $city_id
    GROUP BY
        t,
        city_id
    ORDER BY t
  |||,
  trips_peskin_ratio_a: |||
    SELECT
        $timeSeries as t,
        sum(case when status_type = 'failed_rides' then count else 0 end) as failed_rides,
        sum(case when status_type = 'successful_rides' then count else 0 end) as successful_rides
    FROM $table

    WHERE
        $timeFilter
        AND city_id = $city_id
    GROUP BY
        t,
        city_id
    ORDER BY t
  |||,
  trips_peskin_ratio_b: |||
    SELECT
        $timeSeries as t,
        sum(case when status_type = 'failed_rides' then count else 0 end) / sum(case when status_type = 'successful_rides' then count else 0 end) as peskin_ratio
    FROM $table

    WHERE
        $timeFilter
        AND city_id = $city_id
    GROUP BY
        t,
        city_id
    ORDER BY t
  |||,
}
