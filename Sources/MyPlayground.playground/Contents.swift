struct Stop {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    
}

let stops = [Stop(id: "blah", name: "blahh", latitude: 5.1, longitude: 20), Stop(id: "blah2", name: "blahh", latitude: 0.3, longitude: 5.0)]

let stoplats = stops.map {$0.latitude}
