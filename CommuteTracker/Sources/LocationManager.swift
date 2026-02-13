import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var isUpdating = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        isUpdating = true

        switch manager.authorizationStatus {
        case .notDetermined:
            print("Location permission not determined, requesting...")
            manager.requestAlwaysAuthorization()
            // Fall back to IP while waiting
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                if self?.location == nil {
                    self?.fetchIPLocation()
                }
            }
        case .authorized, .authorizedAlways:
            print("Location authorized, requesting GPS location...")
            manager.requestLocation()
            // Fall back to IP after 5 seconds if GPS is slow
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                if self?.location == nil {
                    print("GPS slow, falling back to IP")
                    self?.fetchIPLocation()
                }
            }
        case .denied, .restricted:
            print("Location denied/restricted, using IP location")
            fetchIPLocation()
        @unknown default:
            fetchIPLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isUpdating = false
        if let location = locations.last {
            print("✅ GPS Location received: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("   Accuracy: \(location.horizontalAccuracy)m")
            self.location = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isUpdating = false
        print("Location error: \(error.localizedDescription)")
        // Fall back to IP-based location
        fetchIPLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorized || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            fetchIPLocation()
        }
    }

    private func fetchIPLocation() {
        print("Fetching IP-based location...")
        guard let url = URL(string: "https://ipapi.co/json/") else {
            print("Failed to create URL")
            DispatchQueue.main.async {
                self.isUpdating = false
            }
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("IP location error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isUpdating = false
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self?.isUpdating = false
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("IP location response: \(String(describing: json))")

                guard let lat = json?["latitude"] as? Double,
                      let lon = json?["longitude"] as? Double else {
                    print("Failed to parse coordinates")
                    DispatchQueue.main.async {
                        self?.isUpdating = false
                    }
                    return
                }

                print("📍 IP Location found: \(lat), \(lon)")
                DispatchQueue.main.async {
                    self?.location = CLLocation(latitude: lat, longitude: lon)
                    self?.isUpdating = false
                }
            } catch {
                print("JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    self?.isUpdating = false
                }
            }
        }.resume()
    }
}
