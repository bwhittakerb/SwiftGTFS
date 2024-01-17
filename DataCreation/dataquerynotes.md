# Notes on querying

trying to do it all in a single sqlite db query with a single example date

```SQL
SELECT arrival_time, trip_headsign FROM stop_times
join TRIPS ON stop_times.trip_id = trips.trip_id
join stops on stop_times.stop_id = stops.stop_id
join calendar_dates ON calendar_dates.service_id = trips.service_id
where stops.stop_id = '1688' AND 
((calendar_dates.date = strftime('%Y%m%d', 'now', 'localtime') 
        AND CAST(SUBSTR(stop_times.arrival_time, 1, 2) AS INTEGER) >= CAST(strftime('%H', 'now', 'localtime', '-1 hour') AS INTEGER)) 
OR (calendar_dates.date = strftime('%Y%m%d', 'now', 'localtime', '-1 day') AND CAST(SUBSTR(stop_times.arrival_time, 1, 2) AS INTEGER) >= 24));
```

Returns in slightly less than a second on an RPi 4