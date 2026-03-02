import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var isUpdating = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private var gpsTimer: DispatchWorkItem?
    private var authTimer: DispatchWorkItem?
    private var ipLocationRetryCount = 0
    private let maxIPRetries = 3
    private var isRequestingAuthorization = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        // Cancel any pending timers
        cancelAllTimers()

        isUpdating = true
        errorMessage = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            guard !isRequestingAuthorization else {
                print("Already requesting authorization, ignoring duplicate request")
                return
            }

            print("Location permission not determined, requesting...")
            isRequestingAuthorization = true
            manager.requestWhenInUseAuthorization()

            // Fall back to IP after waiting for auth
            let timer = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.location == nil {
                    print("Authorization timeout, falling back to IP")
                    self.fetchIPLocation()
                }
            }
            authTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timer)

        case .authorizedAlways, .authorizedWhenInUse:
            print("Location authorized, requesting GPS location...")
            manager.requestLocation()

            // Fall back to IP after 5 seconds if GPS is slow
            let timer = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.location == nil {
                    print("GPS timeout, falling back to IP")
                    self.fetchIPLocation()
                }
            }
            gpsTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timer)

        case .denied, .restricted:
            print("Location denied/restricted, using IP location")
            errorMessage = "Location access denied. Using approximate location."
            fetchIPLocation()

        @unknown default:
            errorMessage = "Unknown location status. Using approximate location."
            fetchIPLocation()
        }
    }

    private func cancelAllTimers() {
        gpsTimer?.cancel()
        gpsTimer = nil
        authTimer?.cancel()
        authTimer = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Cancel fallback timers since GPS succeeded
        cancelAllTimers()

        isUpdating = false
        errorMessage = nil
        ipLocationRetryCount = 0 // Reset retry count on success

        if let location = locations.last {
            print("✅ GPS Location received: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("   Accuracy: \(location.horizontalAccuracy)m")
            self.location = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        cancelAllTimers()

        print("❌ GPS Location error: \(error.localizedDescription)")

        // Check for specific error types
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorMessage = "Location access denied. Using approximate location."
            case .network:
                errorMessage = "Network error. Using approximate location."
            case .locationUnknown:
                errorMessage = "Location unavailable. Using approximate location."
            default:
                errorMessage = "Unable to get precise location. Using approximate location."
            }
        }

        // Fall back to IP-based location
        fetchIPLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        isRequestingAuthorization = false

        print("Authorization status changed to: \(authorizationStatus.rawValue)")

        // Cancel auth timer since we got a response
        authTimer?.cancel()
        authTimer = nil

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            print("Authorization granted, requesting location...")
            manager.requestLocation()

            // Set GPS fallback timer
            let timer = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.location == nil {
                    print("GPS timeout after authorization, falling back to IP")
                    self.fetchIPLocation()
                }
            }
            gpsTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timer)

        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            errorMessage = "Location access denied. Using approximate location."
            fetchIPLocation()
        }
    }

    private func fetchIPLocation(retryDelay: TimeInterval = 0) {
        guard ipLocationRetryCount < maxIPRetries else {
            print("❌ Max IP location retries exceeded")
            DispatchQueue.main.async {
                self.isUpdating = false
                self.errorMessage = "Unable to determine location. Please check your connection."
            }
            return
        }

        let attempt = ipLocationRetryCount + 1
        print("Fetching IP-based location (attempt \(attempt)/\(maxIPRetries))...")

        // Apply retry delay with exponential backoff
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            guard let self = self else { return }

            guard let url = URL(string: "https://ipapi.co/json/") else {
                print("Failed to create URL")
                DispatchQueue.main.async {
                    self.isUpdating = false
                    self.errorMessage = "Failed to initialize location service."
                }
                return
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 10.0
            request.cachePolicy = .reloadIgnoringLocalCacheData

            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ IP location error: \(error.localizedDescription)")
                    self.handleIPLocationFailure()
                    return
                }

                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse {
                    print("IP location response code: \(httpResponse.statusCode)")

                    if httpResponse.statusCode == 429 {
                        print("⚠️ Rate limited by IP location service")
                        DispatchQueue.main.async {
                            self.errorMessage = "Location service rate limited. Retrying..."
                        }
                        self.handleIPLocationFailure()
                        return
                    }

                    if httpResponse.statusCode != 200 {
                        print("❌ HTTP error: \(httpResponse.statusCode)")
                        self.handleIPLocationFailure()
                        return
                    }
                }

                guard let data = data else {
                    print("❌ No data received")
                    self.handleIPLocationFailure()
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    print("IP location response: \(String(describing: json))")

                    // Check for error in response
                    if let error = json?["error"] as? Bool, error == true {
                        print("❌ API returned error")
                        self.handleIPLocationFailure()
                        return
                    }

                    guard let lat = json?["latitude"] as? Double,
                          let lon = json?["longitude"] as? Double else {
                        print("❌ Failed to parse coordinates")
                        self.handleIPLocationFailure()
                        return
                    }

                    print("✅ IP Location found: \(lat), \(lon)")
                    DispatchQueue.main.async {
                        self.location = CLLocation(latitude: lat, longitude: lon)
                        self.isUpdating = false
                        self.ipLocationRetryCount = 0 // Reset on success
                        self.errorMessage = nil
                    }
                } catch {
                    print("❌ JSON parsing error: \(error)")
                    self.handleIPLocationFailure()
                }
            }.resume()
        }
    }

    private func handleIPLocationFailure() {
        ipLocationRetryCount += 1

        if ipLocationRetryCount < maxIPRetries {
            // Exponential backoff: 1s, 2s, 4s
            let delay = pow(2.0, Double(ipLocationRetryCount - 1))
            print("⏳ Retrying in \(delay)s...")
            DispatchQueue.main.async {
                self.errorMessage = "Retrying location lookup..."
            }
            fetchIPLocation(retryDelay: delay)
        } else {
            print("❌ All IP location attempts failed")
            DispatchQueue.main.async {
                self.isUpdating = false
                self.errorMessage = "Unable to determine location. Please check your connection and try again."
            }
        }
    }
}
