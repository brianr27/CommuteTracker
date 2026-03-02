import Foundation
import CoreLocation
import Combine

class CommuteManager: ObservableObject {
    @Published var homeDrivingTime: String?
    @Published var homeDrivingDistance: String?
    @Published var homeTransitTime: String?
    @Published var homeTransitDistance: String?

    @Published var officeDrivingTime: String?
    @Published var officeDrivingDistance: String?
    @Published var officeTransitTime: String?
    @Published var officeTransitDistance: String?

    @Published var statusMessage = "Ready"
    @Published var lastUpdate: Date?

    func updateCommuteTimes(from location: CLLocation, homeAddress: String, officeAddress: String, apiKey: String) {
        statusMessage = "Calculating routes..."

        let origin = "\(location.coordinate.latitude),\(location.coordinate.longitude)"

        // Fetch all commute times
        fetchCommuteTime(origin: origin, destination: homeAddress, mode: "driving", apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.homeDrivingTime = result?.duration
                self?.homeDrivingDistance = result?.distance
            }
        }

        fetchCommuteTime(origin: origin, destination: homeAddress, mode: "transit", apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.homeTransitTime = result?.duration
                self?.homeTransitDistance = result?.distance
            }
        }

        fetchCommuteTime(origin: origin, destination: officeAddress, mode: "driving", apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.officeDrivingTime = result?.duration
                self?.officeDrivingDistance = result?.distance
            }
        }

        fetchCommuteTime(origin: origin, destination: officeAddress, mode: "transit", apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.officeTransitTime = result?.duration
                self?.officeTransitDistance = result?.distance
                self?.statusMessage = "Ready"
                self?.lastUpdate = Date()
            }
        }
    }

    private func fetchCommuteTime(origin: String, destination: String, mode: String, apiKey: String, completion: @escaping (CommuteResult?) -> Void) {
        print("🚗 Fetching \(mode) route: \(origin) → \(destination)")

        // Check if API key is provided
        guard !apiKey.isEmpty else {
            print("❌ No API key configured!")
            completion(nil)
            return
        }

        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/distancematrix/json")!
        components.queryItems = [
            URLQueryItem(name: "origins", value: origin),
            URLQueryItem(name: "destinations", value: destination),
            URLQueryItem(name: "mode", value: mode),
            URLQueryItem(name: "departure_time", value: "now"),
            URLQueryItem(name: "traffic_model", value: "best_guess"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            print("❌ Failed to create URL")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ No data received")
                completion(nil)
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Failed to parse JSON")
                completion(nil)
                return
            }

            // Check for API errors
            if let status = json["status"] as? String, status != "OK" {
                print("❌ Google Maps API error: \(status)")
                if let errorMessage = json["error_message"] as? String {
                    print("   Error message: \(errorMessage)")
                }
                completion(nil)
                return
            }

            guard let rows = json["rows"] as? [[String: Any]],
                  let elements = rows.first?["elements"] as? [[String: Any]],
                  let element = elements.first else {
                print("❌ Invalid response structure")
                completion(nil)
                return
            }

            let elementStatus = element["status"] as? String
            print("   Element status: \(elementStatus ?? "unknown")")

            guard elementStatus == "OK" else {
                print("❌ Route not found or invalid")
                completion(nil)
                return
            }

            let duration = (element["duration_in_traffic"] as? [String: Any])?["text"] as? String
                ?? (element["duration"] as? [String: Any])?["text"] as? String
            let distance = (element["distance"] as? [String: Any])?["text"] as? String

            print("✅ \(mode): \(duration ?? "?") (\(distance ?? "?"))")

            completion(CommuteResult(duration: duration, distance: distance))
        }.resume()
    }
}

struct CommuteResult {
    let duration: String?
    let distance: String?
}
