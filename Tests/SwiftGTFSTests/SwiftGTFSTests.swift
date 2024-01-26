import XCTest
import SwiftGTFS

final class PerformanceTests: XCTestCase {

    let testLat = 53.54077042545684 //53.54092272954773
    let testLon = -113.50812525829596 //-113.52495148525607

    func testPerformanceOfGettingStops() {
        self.measure {
            NearbyBusses.retrieveStops(location: Coordinates(lat: 53.54092272954773, long: -113.52495148525607))
        }
    }
    func testPerformanceOfGettingArrivals() {
        let result = NearbyBusses.retrieveStops(location: Coordinates(lat: 53.54092272954773, long: -113.52495148525607))
        self.measure {
            let arrivalsResult = NearbyBusses.retrieveRecentArrivalsByStop(stops: result, arrivalThresholdInHours: 1)
        }
    }

    func testGettingArrivals() {
        let result = NearbyBusses.retrieveStops(location: Coordinates(lat: testLat, long: testLon))
        let arrivalsResult = NearbyBusses.retrieveRecentArrivalsByStop(stops: result, arrivalThresholdInHours: 1)
        print(arrivalsResult)
    }
}

//NearbyBusses.retrieveRecentArrivalsByStop(stops: result, arrivalThresholdInHours: 1)