import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var currentLocation: CLLocation?
    @Published var locationName: String = ""
    @Published var searchResults: [LocationResult] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    struct LocationResult: Identifiable {
        let id = UUID()
        let name: String
        let location: CLLocation
    }
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        print("Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func searchLocations(_ searchText: String) async {
        guard !searchText.isEmpty else {
            print("Empty search text")
            await MainActor.run { searchResults = [] }
            return
        }
        
        do {
            print("Geocoding address: \(searchText)")
            let locations = try await geocoder.geocodeAddressString(searchText)
            print("Found \(locations.count) locations")
            
            await MainActor.run {
                searchResults = locations.map { place in
                    let components = [
                        place.locality,
                        place.administrativeArea,
                        place.country
                    ].compactMap { $0 }
                    
                    let name = components.joined(separator: ", ")
                    print("Location: \(name)")
                    
                    return LocationResult(
                        name: name,
                        location: place.location ?? CLLocation()
                    )
                }
            }
        } catch {
            print("Geocoding error: \(error)")
            await MainActor.run { searchResults = [] }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization status changed: \(manager.authorizationStatus.rawValue)")
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        print("Location updated: \(location.coordinate)")
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    await MainActor.run {
                        self.locationName = [
                            placemark.locality,
                            placemark.administrativeArea
                        ].compactMap { $0 }
                         .joined(separator: ", ")
                    }
                }
            } catch {
                print("Reverse geocoding error: \(error)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
} 