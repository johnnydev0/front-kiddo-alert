# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KidoAlert** is an iOS SwiftUI app for arrival/departure alerts for children at important locations (school, home, activities).

**Official Subtitle:** "Alertas de chegada para quem você ama"

**Key Philosophy:**
- Informs important events only (arrival/departure) - NOT surveillance
- No continuous tracking, no route recording
- Battery, privacy, and clarity first
- Requires explicit child consent

## Build Commands

```bash
# Open in Xcode (recommended)
open alert.xcodeproj

# Build via command line
xcodebuild -project alert.xcodeproj -scheme alert -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Configuration:** iOS 16.2+, Swift 5.0, iPhone/iPad

## Testing on Simulator

1. Build and run (Cmd+R in Xcode)
2. Grant "Always" location permission when prompted
3. Set custom location: Simulator menu → Features → Location → Custom Location
4. Test coordinates (São Paulo):
   - Centro: -23.5505, -46.6333
   - School mock: -23.5489, -46.6388
   - Home mock: -23.5520, -46.6350

**Reset app data:** `alert/reset-app-data.sh`

## Architecture

### Two User Modes (Single App)

| Mode | Purpose |
|------|---------|
| **Responsável (Guardian)** | View children on map, create geofence alerts, view history, manage alerts |
| **Criança (Child)** | Ultra-simple interface: status display + pause/resume button only |

### State Management

- `AppState` - Central @StateObject managing all app state
- `LocationManager` - CoreLocation services + geofencing
- `DataManager` - UserDefaults persistence with Codable JSON

### Data Persistence

All data persists to UserDefaults with Codable encoding:
- `alerts` - Geofence alerts (LocationAlert)
- `historyEvents` - Event timeline (HistoryEvent)
- `children` - Child list
- `userMode` - Guardian or child mode
- `hasSeenPermissionExplanation` - Onboarding flag

### Geofencing

- Default radius: 100 meters
- Update interval: 5 minutes (configurable for future .env)
- Entry/exit detection via CLCircularRegion

## Current State: Phase 2 Complete

**Implemented:**
- Real location services (CoreLocation)
- Permission management (Always/WhenInUse)
- Geofencing with entry/exit detection
- Local data persistence (UserDefaults)
- Pause/resume location sharing

**NOT implemented (Phase 3+):**
- Backend/API integration
- Push notifications
- Real authentication
- Multi-device sync
- Real invite system

**Do not implement Phase 3+ features without explicit approval.**

## Key Files

| File | Purpose |
|------|---------|
| `alertApp.swift` | App entry point |
| `ContentView.swift` | Root view with permission flow routing |
| `Models.swift` | Data models: Child, LocationAlert, HistoryEvent, etc. |
| `AppState.swift` | Global state management |
| `LocationManager.swift` | CoreLocation + geofencing logic |
| `DataManager.swift` | UserDefaults persistence |

## Design Principles

- "App for lazy people" - minimal interaction required
- Neutral, calm language (never alarmist)
- SwiftUI native components, neutral colors
- Clear states always visible
- Example: "João chegou na escola" ✅ (not surveillance-like language)
