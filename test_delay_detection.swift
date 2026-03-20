#!/usr/bin/env swift

import Foundation

// Test the duration parsing logic
func parseDurationToMinutes(_ duration: String) -> Int? {
    let components = duration.lowercased().components(separatedBy: " ")
    var totalMinutes = 0

    for i in 0..<components.count {
        let component = components[i]

        if component.contains("hour") {
            if i > 0, let hours = Int(components[i - 1]) {
                totalMinutes += hours * 60
            }
        } else if component.contains("min") {
            if i > 0, let mins = Int(components[i - 1]) {
                totalMinutes += mins
            }
        }
    }

    return totalMinutes > 0 ? totalMinutes : nil
}

// Test the delay detection logic
func testDelayDetection(currentDuration: String, baselineMinutes: Int, delayThreshold: Int) {
    print("\n" + String(repeating: "=", count: 60))
    print("Testing: \(currentDuration)")
    print(String(repeating: "=", count: 60))

    guard let currentMinutes = parseDurationToMinutes(currentDuration) else {
        print("❌ Failed to parse duration: \(currentDuration)")
        return
    }

    print("📊 Current time: \(currentMinutes) minutes")
    print("📊 Baseline time: \(baselineMinutes) minutes")

    let delayMinutes = currentMinutes - baselineMinutes
    print("📊 Delay: \(delayMinutes) minutes")

    if delayMinutes > delayThreshold {
        print("🚨 ALERT! Traffic delay of \(delayMinutes) mins exceeds threshold of \(delayThreshold) mins")
        print("📱 Notification would be sent:")
        print("   Title: 🚨 Traffic Delay Alert")
        print("   Body: Home is delayed by \(delayMinutes) mins! Current time: \(currentDuration)")
    } else if delayMinutes > 0 {
        print("⚠️  Minor delay of \(delayMinutes) mins (below \(delayThreshold) min threshold)")
    } else if delayMinutes == 0 {
        print("✅ On time! No delay")
    } else {
        print("🎉 Faster than baseline by \(abs(delayMinutes)) mins")
    }
}

print("\n🧪 COMMUTE DELAY DETECTION TEST SUITE")
print("=====================================\n")

// Test scenarios for Mass Pike (Boston to West Newton)
let baselineTime = 20  // 20 minutes baseline (normal traffic)
let delayThreshold = 10  // Alert on 10+ minute delays

print("\n📍 Route: Boston → West Newton Exit (Mass Pike)")
print("⏱️  Baseline: \(baselineTime) minutes")
print("🚨 Alert Threshold: \(delayThreshold) minutes\n")

// Test Case 1: Normal traffic - no alert
testDelayDetection(
    currentDuration: "20 mins",
    baselineMinutes: baselineTime,
    delayThreshold: delayThreshold
)

// Test Case 2: Light delay - no alert
testDelayDetection(
    currentDuration: "25 mins",
    baselineMinutes: baselineTime,
    delayThreshold: delayThreshold
)

// Test Case 3: Medium delay - no alert (just under threshold)
testDelayDetection(
    currentDuration: "29 mins",
    baselineMinutes: baselineTime,
    delayThreshold: delayThreshold
)

// Test Case 4: Significant delay - ALERT!
testDelayDetection(
    currentDuration: "31 mins",
    baselineMinutes: baselineTime,
    delayThreshold: delayThreshold
)

// Test Case 5: Heavy traffic - ALERT!
testDelayDetection(
    currentDuration: "45 mins",
    baselineMinutes: baselineTime,
    delayThreshold: delayThreshold
)

// Test Case 6: Severe congestion - ALERT!
testDelayDetection(
    currentDuration: "1 hour 5 mins",
    baselineMinutes: baselineTime,
    delayThreshold: delayThreshold
)

// Test Case 7: Better than normal
testDelayDetection(
    currentDuration: "15 mins",
    baselineMinutes: baselineTime,
    delayThreshold: delayThreshold
)

print("\n" + String(repeating: "=", count: 60))
print("✅ Test Suite Complete!")
print(String(repeating: "=", count: 60) + "\n")

// Test parsing different duration formats
print("\n🧪 DURATION PARSING TESTS")
print("=========================\n")

let testDurations = [
    "20 mins",
    "1 hour 5 mins",
    "45 mins",
    "2 hours 30 mins",
    "15 mins"
]

for duration in testDurations {
    if let minutes = parseDurationToMinutes(duration) {
        print("✅ '\(duration)' → \(minutes) minutes")
    } else {
        print("❌ Failed to parse: '\(duration)'")
    }
}

print("\n")
