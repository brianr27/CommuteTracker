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
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rows = json["rows"] as? [[String: Any]],
                  let elements = rows.first?["elements"] as? [[String: Any]],
                  let element = elements.first,
                  let status = element["status"] as? String,
                  status == "OK" else {
                completion(nil)
                return
            }

            let duration = (element["duration_in_traffic"] as? [String: Any])?["text"] as? String
                ?? (element["duration"] as? [String: Any])?["text"] as? String
            let distance = (element["distance"] as? [String: Any])?["text"] as? String

            completion(CommuteResult(duration: duration, distance: distance))
        }.resume()
    }
}

struct CommuteResult {
    let duration: String?
    let distance: String?
}
