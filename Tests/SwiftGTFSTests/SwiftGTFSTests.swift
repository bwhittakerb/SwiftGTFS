import XCTest
import SwiftGTFS

final class PerformanceTests: XCTestCase {
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
}

//NearbyBusses.retrieveRecentArrivalsByStop(stops: result, arrivalThresholdInHours: 1)