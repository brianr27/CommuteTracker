import SwiftUI
import CoreLocation

struct ContentView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var commuteManager: CommuteManager
    @ObservedObject var settings = SettingsManager.shared
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("🚗 Commute Tracker")
                    .font(.headline)
                Spacer()
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            if showSettings {
                settingsView
            } else {
                mainView
            }
        }
        .frame(width: 350, height: showSettings ? 300 : 400)
        .onAppear {
            locationManager.requestLocation()
            updateCommuteTimes()
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Google Maps API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("Keychain")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                TextField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Home Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Address", text: $settings.homeAddress)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Office Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Address", text: $settings.officeAddress)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            HStack {
                Button("Done") {
                    showSettings = false
                    updateCommuteTimes()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    func updateCommuteTimes() {
        if locationManager.location == nil && !locationManager.isUpdating {
            commuteManager.statusMessage = "Getting location..."
            locationManager.requestLocation()

            // Retry after a delay if still no location
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [self] in
                if let location = locationManager.location {
                    commuteManager.updateCommuteTimes(
                        from: location,
                        homeAddress: settings.homeAddress,
                        officeAddress: settings.officeAddress,
                        apiKey: settings.apiKey
                    )
                } else {
                    commuteManager.statusMessage = "Failed to get location"
                }
            }
            return
        }

        guard let location = locationManager.location else {
            commuteManager.statusMessage = "Getting location..."
            return
        }

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
            NSWorkspace.shared.open(url)
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
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0), lineWidth: 2)
        )
        .contentShape(Rectangle())
    }
}
