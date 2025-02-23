//
//  ContentView.swift
//  TideTimes
//
//  Created by Peter Chua-Lao on 23/2/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var searchText = ""
    @State private var tideData: NetworkManager.TideData?
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Location Search
                    SearchBar(
                        searchText: $searchText,
                        isSearching: $isSearching,
                        locationManager: locationManager,
                        onLocationSelected: { location in
                            Task {
                                await fetchTideData(
                                    latitude: location.latitude,
                                    longitude: location.longitude
                                )
                            }
                        }
                    )
                    .padding(.horizontal)
                    
                    if let location = settingsManager.savedLocation {
                        Text(location.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    if let error = errorMessage {
                        ErrorView(message: error)
                    } else if let tideData = tideData {
                        TideContentView(tideData: tideData, dateFormatter: dateFormatter)
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tide Times")
            .background(Color(.systemGroupedBackground))
            .task {
                locationManager.requestLocationPermission()
                if let location = settingsManager.savedLocation {
                    await fetchTideData(latitude: location.latitude, longitude: location.longitude)
                }
            }
        }
    }
    
    private func fetchTideData(latitude: Double, longitude: Double) async {
        do {
            errorMessage = nil
            tideData = try await NetworkManager.shared.fetchTideData(
                latitude: latitude,
                longitude: longitude
            )
        } catch {
            errorMessage = "Error fetching tide data: \(error.localizedDescription)"
            print("Error fetching tide data: \(error)")
        }
    }
}

struct TideContentView: View {
    let tideData: NetworkManager.TideData
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(spacing: 16) {
            // Graph
            GraphView(tideData: tideData, currentTime: Date())
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
            
            // Extremes Summary
            ExtremesView(tideData: tideData, dateFormatter: dateFormatter)
            
            // 24 Hour Table
            TideTableView(tideData: tideData, dateFormatter: dateFormatter)
        }
    }
}

struct ExtremesView: View {
    let tideData: NetworkManager.TideData
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Extremes")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                ForEach(tideData.extremes.prefix(4), id: \.dt) { extreme in
                    VStack(spacing: 8) {
                        Text(extreme.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f m", extreme.height))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(dateFormatter.string(from: Date(timeIntervalSince1970: extreme.dt)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct TideTableView: View {
    let tideData: NetworkManager.TideData
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("24 Hour Forecast")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(Array(tideData.heights.prefix(24).enumerated()), id: \.element.dt) { index, height in
                    HStack {
                        Text(dateFormatter.string(from: Date(timeIntervalSince1970: height.dt)))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f m", height.height))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(index % 2 == 0 ? Color(.systemBackground) : Color(.secondarySystemBackground))
                }
            }
            .cornerRadius(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @ObservedObject var locationManager: LocationManager
    @StateObject private var settingsManager = SettingsManager.shared
    let onLocationSelected: (SettingsManager.SavedLocation) -> Void
    
    var body: some View {
        VStack {
            TextField("Search location...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocorrectionDisabled()
                .onSubmit {
                    // Trigger search when user hits return
                    Task {
                        print("Searching for location: \(searchText)")
                        await locationManager.searchLocations(searchText)
                    }
                }
                .onChange(of: searchText) { newValue in
                    guard newValue.count > 2 else { return } // Only search if more than 2 characters
                    Task {
                        print("Searching for: \(newValue)")
                        await locationManager.searchLocations(newValue)
                    }
                }
            
            // Show search results
            if !locationManager.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(locationManager.searchResults) { result in
                            Button(action: {
                                print("Selected location: \(result.name)")
                                let savedLocation = SettingsManager.SavedLocation(
                                    name: result.name,
                                    latitude: result.location.coordinate.latitude,
                                    longitude: result.location.coordinate.longitude
                                )
                                settingsManager.savedLocation = savedLocation
                                searchText = ""
                                onLocationSelected(savedLocation)
                            }) {
                                Text(result.name)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager.shared)
        .environmentObject(SettingsManager.shared)
        .onAppear {
            NetworkManager.shared.useMockData = true
        }
}
