# CommuteTracker

A native macOS menu bar app that shows real-time commute times to your home and office.

![Menu Bar App](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- 🚗 **Native macOS menu bar app** - Lives in your menu bar, always accessible
- 📍 **Automatic location detection** - Uses GPS with IP fallback
- 🚙 **Dual mode support** - Shows both driving and transit times
- 🚦 **Real-time traffic** - Uses Google Maps API for accurate ETAs
- ⚙️ **Easy configuration** - Simple settings for home, office, and API key
- 🎨 **Native SwiftUI design** - Beautiful, modern macOS interface

## Screenshots

Click the car icon in your menu bar to see:
- Current commute times to home and office
- Both driving and transit options
- Real-time traffic conditions
- Distance information

## Installation

### Prerequisites

- macOS 13.0 or later
- Google Maps API key with Distance Matrix API enabled

### Getting a Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable the **Distance Matrix API**
4. Create an API key
5. Restrict the key to Distance Matrix API for security

### Build and Run

```bash
cd CommuteTracker
swift build
open ../CommuteTracker.app
```

The app will appear in your menu bar as a car icon 🚗

## First Run Setup

1. Click the car icon in your menu bar
2. Click the gear icon (⚙️) to open settings
3. Enter:
   - Your Google Maps API key
   - Your home address
   - Your office address
4. Click "Done"
5. Click "Refresh Now" to see your commute times

## Location Permission

When you first run the app, macOS will ask for location permission. Click "Allow" to enable GPS-based location detection.

If you deny permission, the app will fall back to IP-based location (less accurate but still functional).

## How It Works

1. **Location Detection**: Uses CoreLocation for GPS, falls back to IP geolocation if unavailable
2. **Route Calculation**: Calls Google Maps Distance Matrix API for both driving and transit modes
3. **Traffic Data**: Requests real-time traffic information for accurate ETAs
4. **Auto-refresh**: Click "Refresh Now" to update commute times

## Project Structure

```
CommuteTracker/
├── Sources/
│   ├── main.swift           # App entry point
│   ├── AppDelegate.swift    # Menu bar setup
│   ├── ContentView.swift    # Main UI
│   ├── LocationManager.swift # GPS/IP location handling
│   └── CommuteManager.swift  # Google Maps API integration
└── Package.swift            # Swift package manifest
```

## Privacy

- Your location is only used locally to calculate commute times
- API requests go directly to Google Maps
- Your API key and addresses are stored in macOS UserDefaults
- No data is sent to any third-party servers

## Development

Built with:
- **Swift 5.9**
- **SwiftUI** for the interface
- **CoreLocation** for GPS
- **URLSession** for API calls

## License

MIT

## Troubleshooting

**"Getting location..." stuck**
- Check that Location Services is enabled in System Settings
- The app will fall back to IP location after 5 seconds

**No commute times showing**
- Verify your Google Maps API key is valid
- Ensure Distance Matrix API is enabled in Google Cloud Console
- Check that billing is enabled (free tier is sufficient)

**Location not accurate**
- Grant location permission in System Settings > Privacy & Security > Location Services
- Find "CommuteTracker" and enable it

## Contributing

Feel free to open issues or submit pull requests!
