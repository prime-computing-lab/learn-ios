import Foundation
import CoreLocation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var savedLocation: SavedLocation? {
        didSet {
            if let location = savedLocation {
                saveLocation(location)
            }
        }
    }
    
    struct SavedLocation: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
    }
    
    private let userDefaults = UserDefaults.standard
    private let locationKey = "savedLocation"
    
    private init() {
        loadSavedLocation()
    }
    
    private func loadSavedLocation() {
        if let data = userDefaults.data(forKey: locationKey),
           let location = try? JSONDecoder().decode(SavedLocation.self, from: data) {
            savedLocation = location
        }
    }
    
    private func saveLocation(_ location: SavedLocation) {
        if let encoded = try? JSONEncoder().encode(location) {
            userDefaults.set(encoded, forKey: locationKey)
        }
    }
} 