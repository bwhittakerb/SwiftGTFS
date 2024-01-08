-- Usage:  $ sqlite3 GTFS/ets.db < GTFS/ets_lookup.sh
-- Usage:  sqlite> .read GTFS/ets_lookup.sh 

-- List of the valid service_id codes for the current date
CREATE VIEW valid_service_ids AS
   SELECT service_id 
   FROM calendar_dates 
   WHERE date == strftime('%Y%m%d', 'now', 'localtime')
   ;

SELECT stop_times.arrival_time, trips.route_id, trips.trip_headsign
   FROM trips, stop_times

   -- Match the trip_id field between the two tables
   WHERE stop_times.trip_id == trips.trip_id

   -- Limit selection to the stops we care about 
   AND stop_times.stop_id IN (1688)

   -- Limit selection to service_ids for the correct day
   AND trips.service_id IN valid_service_ids

   -- Limit selection to the next hour from now
   AND stop_times.arrival_time > strftime(
                                 '%H:%M:%S', 'now', 'localtime', '-5 minutes')
   AND stop_times.arrival_time < strftime(
                                 '%H:%M:%S', 'now', 'localtime', '+1 hour')
   ORDER BY stop_times.arrival_time
   ;

-- Clean Up
DROP VIEW valid_service_ids;