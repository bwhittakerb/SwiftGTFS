# SwiftGTFS

This is a project I made to learn how to write in compiled, type safe languages. I'm sure I've made lots of mistakes.

It's meant to be a library so that other programs can get nearby stop data formatted as an object

using invocations like:

```Swift
let stopResults = NearbyBusses.retrieveStops(location: Coordinates(lat: someLatitudeInEdmontonHere, long: someLongitudeInEdmontonHere))

let arrivalsResults = NearbyBusses.retrieveRecentArrivalsByStop(stops: stopResults, arrivalThresholdInHours: 1)
```