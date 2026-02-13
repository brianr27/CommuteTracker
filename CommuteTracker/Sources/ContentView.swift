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

                    CommuteCard(
                        title: "🏢 Office",
                        drivingTime: commuteManager.officeDrivingTime,
                        drivingDistance: commuteManager.officeDrivingDistance,
                        transitTime: commuteManager.officeTransitTime,
                        transitDistance: commuteManager.officeTransitDistance
                    )
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
                Text("Google Maps API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Home Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Address", text: $homeAddress)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Office Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Address", text: $officeAddress)
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
                        homeAddress: homeAddress,
                        officeAddress: officeAddress,
                        apiKey: apiKey
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
            homeAddress: homeAddress,
            officeAddress: officeAddress,
            apiKey: apiKey
        )
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
            Text(title)
                .font(.headline)

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
    }
}
