import SwiftUI
import CoreLocation

struct ContentView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var commuteManager: CommuteManager
    @ObservedObject var settings = SettingsManager.shared
    @State private var showSettings = false
    @State private var hasRequestedInitialUpdate = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showSettings {
                    settingsView
                } else {
                    mainView
                }
            }
            .navigationTitle("🚗 Commute Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                // Request location on first launch
                if !hasRequestedInitialUpdate {
                    hasRequestedInitialUpdate = true
                    locationManager.requestLocation()
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                // Automatically update commute times when location changes
                if newLocation != nil && !settings.apiKey.isEmpty {
                    updateCommuteTimes()
                }
            }
        }
    }

    var mainView: some View {
        VStack(spacing: 16) {
            // Status
            VStack(spacing: 4) {
                HStack {
                    if locationManager.isUpdating {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(commuteManager.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let lastUpdate = commuteManager.lastUpdate {
                        Text(lastUpdate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Show location error message if any
                if let errorMessage = locationManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .imageScale(.small)
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 2)
                }

                // Show current location for debugging
                if let location = locationManager.location {
                    HStack(spacing: 4) {
                        Text("📍 \(String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(locationManager.locationSource)
                            .font(.caption2)
                            .foregroundColor(locationManager.locationSource.starts(with: "GPS") ? .green : .orange)
                            .bold()
                    }
                    .opacity(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Commute cards
            ScrollView {
                VStack(spacing: 12) {
                    CommuteCard(
                        title: "🏠 Home",
                        drivingTime: commuteManager.homeDrivingTime,
                        drivingDistance: commuteManager.homeDrivingDistance,
                        transitTime: commuteManager.homeTransitTime,
                        transitDistance: commuteManager.homeTransitDistance
                    )
                    .onTapGesture {
                        openGoogleMaps(destination: settings.homeAddress, mode: "driving")
                    }

                    CommuteCard(
                        title: "🏢 Office",
                        drivingTime: commuteManager.officeDrivingTime,
                        drivingDistance: commuteManager.officeDrivingDistance,
                        transitTime: commuteManager.officeTransitTime,
                        transitDistance: commuteManager.officeTransitDistance
                    )
                    .onTapGesture {
                        openGoogleMaps(destination: settings.officeAddress, mode: "driving")
                    }
                }
                .padding(.horizontal)
            }

            // Refresh button
            Button(action: updateCommuteTimes) {
                Label("Refresh Now", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    var settingsView: some View {
        Form {
            Section(header: Text("Google Maps API Key")) {
                TextField("API Key", text: $settings.apiKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section(header: Text("Addresses")) {
                TextField("Home Address", text: $settings.homeAddress)
                TextField("Office Address", text: $settings.officeAddress)
            }

            Section {
                Button("Done") {
                    showSettings = false
                    updateCommuteTimes()
                }
            }
        }
    }

    func updateCommuteTimes() {
        // Check if we have API key and addresses configured
        guard !settings.apiKey.isEmpty else {
            commuteManager.statusMessage = "Configure API key in Settings"
            return
        }

        guard !settings.homeAddress.isEmpty || !settings.officeAddress.isEmpty else {
            commuteManager.statusMessage = "Configure addresses in Settings"
            return
        }

        // If no location yet, request it
        if locationManager.location == nil {
            if !locationManager.isUpdating {
                commuteManager.statusMessage = "Getting location..."
                locationManager.requestLocation()
            }
            // The .onChange observer will trigger update when location arrives
            return
        }

        // We have location, fetch commute times
        guard let location = locationManager.location else { return }

        commuteManager.updateCommuteTimes(
            from: location,
            homeAddress: settings.homeAddress,
            officeAddress: settings.officeAddress,
            apiKey: settings.apiKey
        )
    }

    func openGoogleMaps(destination: String, mode: String) {
        guard let location = locationManager.location else { return }

        let origin = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        let encodedOrigin = origin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? origin
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destination

        // Google Maps URL with directions
        let urlString = "https://www.google.com/maps/dir/?api=1&origin=\(encodedOrigin)&destination=\(encodedDestination)&travelmode=\(mode)"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct CommuteCard: View {
    let title: String
    let drivingTime: String?
    let drivingDistance: String?
    let transitTime: String?
    let transitDistance: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.up.forward.circle.fill")
                    .foregroundColor(.blue)
                    .imageScale(.small)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("Driving")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(drivingTime ?? "--")
                        .font(.title2)
                        .bold()
                    Text(drivingDistance ?? "--")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "tram.fill")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("Transit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(transitTime ?? "--")
                        .font(.title2)
                        .bold()
                    Text(transitDistance ?? "--")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
