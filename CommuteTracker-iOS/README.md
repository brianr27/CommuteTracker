# CommuteTracker iOS

iOS version of CommuteTracker - track commute times to home and office using Google Maps API.

## Setup Instructions

1. **Open in Xcode**
   - Double-click `CommuteTracker-iOS.xcodeproj`
   - Or open from Xcode: File → Open → Select the project

2. **Configure Signing**
   - Select the project in the navigator
   - Go to "Signing & Capabilities"
   - Select your Team from the dropdown
   - Xcode will automatically create a bundle identifier

3. **Build and Run**
   - Connect your iPhone or select an iOS Simulator
   - Press Cmd+R or click the Play button

## First Launch

1. The app will request location permission - tap "Allow"
2. Tap the gear icon to configure:
   - Your Google Maps API Key
   - Home address
   - Office address
3. Tap "Done" to save and refresh

## Features

- Real-time commute calculations using Google Maps
- Driving and transit times/distances
- GPS location with IP-based fallback
- Tap any card to open Google Maps with directions

## Requirements

- iOS 15.0 or later
- Google Maps Distance Matrix API key
- Location permissions

## Notes

- The API key in the code is from the original macOS app - replace it with your own
- First launch may take a few seconds to get GPS lock
- Falls back to IP-based location if GPS is unavailable
