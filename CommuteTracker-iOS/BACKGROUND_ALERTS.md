# Background Traffic Delay Alerts

Your iOS app now supports automatic background monitoring for traffic delays!

## How It Works

The app will automatically check your commute times every **15 minutes** in the background and alert you when there's a **10+ minute delay** compared to your baseline times.

## Setup Instructions

### 1. Add Files to Xcode Project

Make sure these new files are added to your Xcode project:
- `NotificationManager.swift`
- `BackgroundTaskManager.swift`

### 2. Configure Alerts

1. Open the app and tap the **Settings** gear icon
2. Enable **"Enable Delay Alerts"**
3. Grant notification permissions when prompted
4. Set your baseline times:
   - Toggle on routes you want to monitor (Home/Office)
   - Tap **"Refresh Now"** when traffic is normal
   - Tap **"Set baseline to current"** to save that time as your baseline
   - Or manually adjust the baseline stepper

### 3. Adjust Settings (Optional)

- **Delay Threshold**: Default is 10 minutes, adjust from 5-30 minutes
- **Baseline Times**: Set different baselines for home and office routes
- **Monitor Routes**: Choose which routes to monitor

### 4. Background Permissions

iOS will ask for these permissions:
- ✅ **Notifications**: Required to receive alerts
- ✅ **Location "When In Use"**: For GPS location
- ⚙️ **Background App Refresh**: Enable in Settings > General > Background App Refresh

## How Background Refresh Works

### iOS Limitations
- iOS controls when background tasks run (usually every 15-30 minutes)
- Background tasks won't run if Low Power Mode is enabled
- iOS may delay tasks if the device is busy or low on battery

### What Happens
1. App schedules background refresh when you go to background
2. iOS wakes the app approximately every 15 minutes
3. App gets your location and checks commute times
4. If delay exceeds threshold, you get a notification:
   > "🚨 Traffic Delay Alert: Home is delayed by 15 mins! Current time: 45 mins"

## Testing Background Alerts

### Simulator Testing
Background tasks don't work reliably in the simulator. Use a real device.

### Real Device Testing
1. Build and run on your iPhone
2. Set up alerts with a very low baseline (e.g., 5 minutes)
3. Put the app in background
4. In Xcode, go to **Debug > Simulate Background Fetch**
5. Check Console for background task logs

### Production Testing
1. Set realistic baseline times during normal traffic
2. Use the app during rush hour to test real delays
3. Monitor notifications

## Baseline Time Recommendations

Set baselines during **typical off-peak times**:
- **Morning**: 10 AM - 11 AM on weekdays
- **Midday**: 1 PM - 3 PM
- **Evening**: 7 PM - 9 PM

Avoid setting baselines during:
- ❌ Rush hour (7-9 AM, 4-7 PM)
- ❌ Weekends (different traffic patterns)
- ❌ Holidays
- ❌ Bad weather

## For Mass Pike (Boston to West Newton)

Example setup:
1. **Set as Home Address**: "West Newton, MA" or specific exit address
2. **Baseline Time**: ~15-20 minutes (off-peak)
3. **Delay Threshold**: 10 minutes
4. **Alert Triggers**: When commute exceeds 25-30 minutes

## Troubleshooting

**Not receiving alerts?**
- Check Settings > Notifications > CommuteTracker is enabled
- Check Settings > General > Background App Refresh is ON
- Disable Low Power Mode
- Make sure alerts are enabled in app settings
- Verify baseline times are set (not 0)

**Alerts too frequent?**
- Increase delay threshold (Settings > 15-20 minutes)
- Tap "Reset Alerts" to clear alert state
- Adjust baseline times if they're too low

**Alerts not triggering?**
- Lower baseline times to test
- Check that routes are enabled for monitoring
- Verify API key is configured correctly
- Check Console logs for errors

## Privacy & Battery

- **Location**: Only accessed when checking commute times
- **Battery**: Minimal impact (~1-2% per day)
- **Data Usage**: Small API calls every 15 minutes
- **Privacy**: No data leaves your device except Google Maps API calls

## Resetting

Tap **"Reset Alerts"** in settings to:
- Clear notification state
- Allow new notifications for routes
- Useful after dismissing an alert and wanting to be alerted again

---

**Note**: iOS background tasks are designed to be battery-efficient and may not run exactly every 15 minutes. For time-critical alerts, keep the app open or check manually before leaving.
