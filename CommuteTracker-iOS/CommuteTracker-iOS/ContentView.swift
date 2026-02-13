import SwiftUI
import CoreLocation

struct ContentView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var commuteManager: CommuteManager
    @AppStorage("homeAddress") private var homeAddress = "27 Howland Rd, West Newton, MA 02465"
    @AppStorage("officeAddress") private var officeAddress = "300 A Street, Boston, MA 02210"
    @AppStorage("googleMapsAPIKey") private var apiKey = "YOUR_API_KEY_HERE"
    @State private var showSettings = false

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
                locationManager.requestLocation()
                updateCommuteTimes()
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

                // Show current location for debugging
                if let location = locationManager.location {
                    Text("📍 \(String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                        openGoogleMaps(destination: homeAddress, mode: "driving")
                    }

                    CommuteCard(
                        title: "🏢 Office",
                        drivingTime: commuteManager.officeDrivingTime,
                        drivingDistance: commuteManager.officeDrivingDistance,
                        transitTime: commuteManager.officeTransitTime,
                        transitDistance: commuteManager.officeTransitDistance
                    )
                    .onTapGesture {
                        openGoogleMaps(destination: officeAddress, mode: "driving")
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
                TextField("API Key", text: $apiKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section(header: Text("Addresses")) {
                TextField("Home Address", text: $homeAddress)
                TextField("Office Address", text: $officeAddress)
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
        if locationManager.location == nil && !locationManager.isUpdating {
            commuteManager.statusMessage = "Getting location..."
            locationManager.requestLocation()

            // Retry after a delay if still no location
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak locationManager, weak commuteManager, homeAddress, officeAddress, apiKey] in
                if let location = locationManager?.location {
                    commuteManager?.updateCommuteTimes(
                        from: location,
                        homeAddress: homeAddress,
                        officeAddress: officeAddress,
                        apiKey: apiKey
                    )
                } else {
                    commuteManager?.statusMessage = "Failed to get location"
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
            homeAddress: homeAddress,
            officeAddress: officeAddress,
            apiKey: apiKey
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
