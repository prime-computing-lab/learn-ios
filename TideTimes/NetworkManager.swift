import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://www.worldtides.info/api/v3" // Update to v3
    private let apiKey: String
    
    var useMockData = false // Add this property
    
    private init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["TESTING"] == "true" {
            self.apiKey = "test_key"
        } else {
            self.apiKey = Config.worldTidesApiKey
        }
        #else
        self.apiKey = Config.worldTidesApiKey
        #endif
    }
    
    struct TideData: Codable {
        let status: Int
        let heights: [TideHeight]
        let extremes: [TideExtreme]
        
        // Make these properties optional since they're not always returned
        let callCount: Int?
        let copyright: String?
        let requestLat: Double?
        let requestLon: Double?
        let responseLat: Double?
        let responseLon: Double?
        let atlas: String?
        
        enum CodingKeys: String, CodingKey {
            case status, heights, extremes, copyright, atlas
            case callCount = "call_count"
            case requestLat = "request_lat"
            case requestLon = "request_lon"
            case responseLat = "response_lat"
            case responseLon = "response_lon"
        }
        
        // Update preview data
        static func preview() -> TideData {
            return TideData(
                status: 200,
                heights: [
                    TideHeight(dt: Date().timeIntervalSince1970, date: "2024-04-01", height: 1.0),
                    TideHeight(dt: Date().timeIntervalSince1970 + 3600, date: "2024-04-01", height: 1.5)
                ],
                extremes: [
                    TideExtreme(dt: Date().timeIntervalSince1970, date: "2024-04-01", height: 1.0, type: "High")
                ],
                callCount: 1,
                copyright: "WorldTides",
                requestLat: 0.0,
                requestLon: 0.0,
                responseLat: 0.0,
                responseLon: 0.0,
                atlas: "WorldTides"
            )
        }
    }
    
    struct TideHeight: Codable {
        let dt: TimeInterval
        let date: String
        let height: Double
    }
    
    struct TideExtreme: Codable {
        let dt: TimeInterval
        let date: String
        let height: Double
        let type: String
    }
    
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case decodingError
        case serverError(Int)
        case apiError(String)
        case noDataAvailable
        case quotaExceeded
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .decodingError:
                return "Could not decode the data"
            case .serverError(let code):
                return "Server error: \(code)"
            case .apiError(let message):
                return message
            case .noDataAvailable:
                return "No tide data available for this location"
            case .quotaExceeded:
                return "API quota exceeded"
            }
        }
    }
    
    // Add this function to help debug API responses
    private func printJSON(_ data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            print("API Response: \(String(decoding: jsonData, as: UTF8.self))")
        }
    }
    
    // Update fetchTideData to include response debugging
    func fetchTideData(latitude: Double, longitude: Double) async throws -> TideData {
        if useMockData {
            print("Using mock data")
            return getMockTideData()
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let urlString = "\(baseURL)?heights&extremes&lat=\(latitude)&lon=\(longitude)&date=\(dateString)&days=1&key=\(apiKey)"
        print("Fetching tide data from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Print the raw response for debugging
            print("Raw response data:")
            printJSON(data)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            // Check for API-specific errors
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let status = json["status"] as? Int, status != 200 {
                    if let error = json["error"] as? String {
                        throw NetworkError.apiError(error)
                    }
                    throw NetworkError.serverError(status)
                }
            }
            
            let decoder = JSONDecoder()
            let tideData = try decoder.decode(TideData.self, from: data)
            print("Successfully decoded tide data")
            return tideData
        } catch {
            print("Network or decoding error: \(error)")
            throw error
        }
    }
    
    // Update getMockTideData() function
    private func getMockTideData() -> TideData {
        let now = Date().timeIntervalSince1970
        let hourInSeconds: TimeInterval = 3600
        let today = Date().formatted(date: .numeric, time: .omitted)
        
        let heights = stride(from: 0, through: 24, by: 1).map { hour in
            TideHeight(
                dt: now + Double(hour) * hourInSeconds,
                date: today,
                height: sin(Double(hour) / 6 * .pi) + 1.5
            )
        }
        
        let extremes = [
            TideExtreme(dt: now + 6 * hourInSeconds, date: today, height: 2.5, type: "High"),
            TideExtreme(dt: now + 12 * hourInSeconds, date: today, height: 0.5, type: "Low"),
            TideExtreme(dt: now + 18 * hourInSeconds, date: today, height: 2.5, type: "High")
        ]
        
        return TideData(
            status: 200,
            heights: heights,
            extremes: extremes,
            callCount: 1,
            copyright: "WorldTides",
            requestLat: 0.0,
            requestLon: 0.0,
            responseLat: 0.0,
            responseLon: 0.0,
            atlas: "WorldTides"
        )
    }
} 
