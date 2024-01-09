import SQLite
import Foundation

// let connectionPath = "/Users/brendan/Builds/data/gtfs/ets.db"
let connectionPath = "/home/brendan/projects/GTFS-ETS/CompiledDB/ets.db"

var greeting = "Hello, playground"

class DatabaseManager {
    static let shared = DatabaseManager()
    private(set) var db: Connection?
    
    let stops = Table("stops")
    let trips = Table("trips")
    let stopTimes = Table("stop_times")
    let calendarDates = Table("calendar_dates")
    let validServiceIDsView = View("valid_service_ids")
    
    let stopLat = Expression<Double>("stop_lat")
    let stopLon = Expression<Double>("stop_lon")
    let date = Expression<Int>("date")
    let stopID = Expression<String>("stop_id")
    let stopName = Expression<String>("stop_name")
    let arrivalTime = Expression<String>("arrival_time")
    let routeID = Expression<String>("route_id")
    let tripHeadsign = Expression<String>("trip_headsign")
    let tripID = Expression<String>("trip_id")
    let serviceID = Expression<String>("service_id")

    //okay let's try to make this index

    private init() {
        
        do {
            db = try Connection(connectionPath)

            // Create the temporary view
            let tempValidServiceView = """
                    CREATE TEMP VIEW IF NOT EXISTS valid_service_ids AS
                           SELECT service_id, date
                           FROM calendar_dates
                           WHERE date == strftime('%Y%m%d', 'now', 'localtime');
                    """
            
            try self.db?.execute(tempValidServiceView)

            
        } catch {
            print("Unable to connect to database: \(error)")
            db = nil
        }
    }
}

extension DatabaseManager {
    func getAllStops() -> [Stop] {
        do {
            // Attempt to fetch all rows from the 'stops' table.
            let rows = try self.db?.prepare(self.stops)
            var stopsArray: [Stop] = []
            for row in rows! {
                // Create a Stop object from each row's columns.
                let stop = Stop(
                    id: row[stopID],
                    name: row[stopName],
                    latitude: row[stopLat],
                    longitude: row[stopLon]
                )
                stopsArray.append(stop)
            }
            return stopsArray
        } catch {
            print("Query failed: \(error)")
            return []
        }
    }
}

extension DatabaseManager {
    func getSelectedStopsAndArrivals(listOfStopIDs: [String]) -> [[String: Any]] {
        
        var queryResult: [[String: Any]] = []
        
        do {
            let nearbyStopsBussesQuery = stopTimes
                .select(stopTimes[arrivalTime], trips[routeID], trips[tripHeadsign], stopTimes[stopID], date, stops[stopLat], stops[stopLon])
                .join(trips, on: stopTimes[tripID] == trips[tripID])
                .join(validServiceIDsView, on: trips[serviceID] == validServiceIDsView[serviceID])
                .join(stops, on: stopTimes[stopID] == stops[stopID])
                .where(listOfStopIDs.contains(stopTimes[stopID]))
            
            let rows = try self.db?.prepare(nearbyStopsBussesQuery)
            
            for row in rows! {
                queryResult.append([
                    "ArrivalTime": row[arrivalTime],
                    "RouteID": row[routeID],
                    "TripHeadsign": row[tripHeadsign],
                    "StopID": row[stopID],
                    "Date": row[date],
                    "StopCoordinates": Coordinates(lat: row[stopLat], long: row[stopLon])
                ])
                
            }
        } catch {
            print("Query failed: \(error)")
            return [[:]]
        }
        return queryResult
    }
    
}

public struct Stop: Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    
    var coordinates: Coordinates {
        return Coordinates(lat: self.latitude, long: self.longitude)
    }
}

public struct Coordinates: Codable {
    let lat: Double
    let long: Double

    // Manual initializer
    public init(lat: Double, long: Double) {
        self.lat = lat
        self.long = long
    }
}

public struct Arrival: Codable {
    let routeID: String
    let arrivalTime: Date
    let headSign: String
}

public struct StopArrivals: Codable {
    let stop: String
    let stopName: String
    let stopCoords: Coordinates
    let Arrivals: [Arrival]
}

public struct NearbyBusses: Codable {
    let atTime: Date
    let coordinates: Coordinates
    let stops: [String]
    let stopArrivals: [StopArrivals]
    
    
//    init(atTime: Date = Date(), coordinates: Coordinates) {
//        self.atTime = atTime
//        self.coordinates = coordinates
//    }
    
    public static func retrieveStops(location: Coordinates, distance: Double = 0.25) -> [Stop] {
        let allStops = DatabaseManager.shared.getAllStops()
        var closeStops: [Stop] = []
        
        for stop in allStops {
            if getDistance(origin: location, point: stop.coordinates) <= distance {
                closeStops.append(
                    Stop(id: stop.id, name: stop.name, latitude: stop.latitude, longitude: stop.longitude)
                )
            }
        }
        return closeStops
        
    }
    
//    static func retrieveAllArrivalsAtStops(stopList: [Stop])
    
    public static func retrieveRecentArrivalsByStop(stops: [Stop], arrivalThresholdInHours: Double) -> [StopArrivals]{
        let dbResults = DatabaseManager.shared.getSelectedStopsAndArrivals(listOfStopIDs: stops.map {$0.id})
        
        var stopArrivalsList: [StopArrivals] = []
        
        let listOfStopIDs = dbResults.compactMap { $0["StopID"] as? String }
        let listOfUniqueStopIDs = Set(listOfStopIDs)
        
        for uniqueID in listOfUniqueStopIDs {
            let listOfArrivals = dbResults.filter {arrival in
                return arrival["StopID"] as? String == uniqueID}
            
            do {
                let arrivalsAtStop = try listOfArrivals.map { dictionary in
                    Arrival(
                        routeID: dictionary["RouteID"] as! String,
                        arrivalTime: try parseDateAndTime(dateString: String(dictionary["Date"] as! Int),                                                                                      timeString: dictionary["ArrivalTime"] as! String),
                        headSign: dictionary["TripHeadsign"] as! String)
                    
                }
                
                let filteredArrivalsAtStop = arrivalsAtStop.filter { arrival in
                    let timeDifference = arrival.arrivalTime.timeIntervalSinceNow
                    return (timeDifference <= arrivalThresholdInHours * 3600 &&
                        timeDifference >= (-5 * 60)) // threshold hours in seconds and last 5 minutes
                }
                
                             
                let stopArrival = StopArrivals(stop: uniqueID, stopName: uniqueID, stopCoords: listOfArrivals.first!["StopCoordinates"] as! Coordinates, Arrivals: filteredArrivalsAtStop)
                
                stopArrivalsList.append(stopArrival)
                
//                print(arrivalsAtStop)
                
            } catch {print(error)}
            
            
            
        }
        return stopArrivalsList
    }
    
    static func parseDateAndTime(dateString: String, timeString: String) throws -> Date {
        enum DateError: Error {
            case invalidDateFormat
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(identifier: "America/Edmonton")
        //time formatter
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = dateFormatter.timeZone
        timeFormatter.dateFormat = "HH:mm:ss"
        // combined formatter
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyyMMdd HH:mm:ss"
        dateTimeFormatter.timeZone = dateFormatter.timeZone
        
        // fix weird time func
        func timeIntervalFromString(_ timeString: String) -> TimeInterval? {
            let components = timeString.split(separator: ":").map(String.init)
            guard components.count == 3,
                  let hours = Int(components[0]),
                  let minutes = Int(components[1]),
                  let seconds = Int(components[2]) else {
                return nil
            }
            return TimeInterval(hours * 3600 + minutes * 60 + seconds)
        }
        
        // Try to parse normally first
        if let date = dateTimeFormatter.date(from: "\(dateString) \(timeString)") {
            return date
        } else {

            guard let duration = timeIntervalFromString(timeString) else {
                throw DateError.invalidDateFormat
            }
            
            // Adjust for overflow past midnight
            // subtracting 24 hours worth of seconds from time:
            let dayDuration: TimeInterval = 24 * 60 * 60
            let subtractedDuration = duration - dayDuration

            func formatDurationToString(_ duration: TimeInterval) -> String {
                let hours = Int(duration) / 3600
                let minutes = Int(duration) % 3600 / 60
                let seconds = Int(duration) % 60

                // This will pad the integers with leading zeros to make them at least two digits long
                return String(format:"%02d:%02d:%02d", hours, minutes, seconds)
            }

            let formattedCorrectedTime = formatDurationToString(subtractedDuration)
            // guard let formattedCorrectedTime = formatter.string(from: subtractedDuration) else {throw DateError.invalidDateFormat}
            
            guard let correctedDate = dateTimeFormatter.date(from: "\(dateString) \(formattedCorrectedTime)")?.addingTimeInterval(dayDuration) else {
                throw DateError.invalidDateFormat
            }
            return correctedDate
        }
    }
    
    
    
    static private func getDistance(origin: Coordinates, point: Coordinates) -> Double {
        let earthRadius: Double = 6371
        let halfPi = Double.pi / 180
        
        let coordDistance = 0.5 - cos((point.lat - origin.lat) * halfPi) / 2 +
                            cos(origin.lat * halfPi) * cos(point.lat * halfPi) *
                            (1 - cos((point.long - origin.long) * halfPi)) / 2
        
        let result = 2.0 * earthRadius * asin(sqrt(coordDistance))
        
        return result
        
    }
}


//let sampleStops = ["1141", "1392", "1688", "1939", "1960"]
//print(info)

// debug testing (commented out)

// let result = NearbyBusses.retrieveStops(location: Coordinates(lat: 53.54092272954773, long: -113.52495148525607))
// let result2 = NearbyBusses.retrieveRecentArrivalsByStop(stops: result, arrivalThresholdInHours: 1)

// let encoder = JSONEncoder()
// encoder.dateEncodingStrategy = .iso8601 // Set the date encoding strategy to ISO 8601 format
// if let encodedData = try? encoder.encode(result2),
//    let jsonString = String(data: encodedData, encoding: .utf8) {
//     print(jsonString)
// }
