# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KidoAlert** is an iOS app for arrival/departure alerts for children at important locations (school, home, activities). The app is designed to reduce anxiety, not enable surveillance.

**Official Subtitle:** "Alertas de chegada para quem você ama"

**Key Philosophy:**
- Informs important events only
- No continuous tracking
- Battery, privacy, and clarity first
- Requires explicit child consent
- NOT a real-time tracking/surveillance app
- No route recording or movement history

## Build Commands

This is a standard Xcode-based SwiftUI iOS project.

**Build and run:**
```bash
cd /Users/user289963/Desktop/kiddoalert/alert
xcodebuild -project alert.xcodeproj -scheme alert -configuration Debug
```

**Or use Xcode:**
- Open `alert.xcodeproj` in Xcode
- Select target device/simulator
- Cmd+R to build and run

**Project Configuration:**
- Deployment Target: iOS 26.2
- Swift Version: 5.0
- Target Devices: iPhone and iPad (1,2)

## Architecture

### Two User Modes (Single App)

The app has two visual modes but is a single application:

**👨‍👩‍👧 Responsável (Guardian) Mode:**
- View map with last known location
- Create geofence alerts
- Receive notifications
- Manage children
- View event history

**🧒 Criança (Child) Mode:**
- Extremely simple interface
- Shows sharing status
- Pause/resume button
- Clear info about who is viewing location
- No complex map or history

### Current Phase: FASE 2 - COMPLETE ✅

**Phase 2 Implemented:**
- ✅ Real location services
- ✅ Permission management (Always/WhenInUse)
- ✅ Geofencing (create, monitor, detect)
- ✅ Local data persistence (UserDefaults)
- ✅ Pause/resume location sharing
- ✅ Real location display on maps

⚠️ **In Phase 2, NOT implemented (reserved for Phase 3+):**
- Backend integration
- Real notifications (push)
- Authentication logic
- Multi-device sync
- Invite system

## Required Screens (Phase 1)

### 1. Splash/Boot
- Logo
- Simple loading
- Smooth transition

### 2. Home Screen (Responsável)
- Card showing:
  - Child name
  - Status ("Em casa", "Na escola", "Compartilhamento pausado")
  - "Ver mapa" button
  - "Atualizado há X min"
  - Battery indicator (mock)
- Tap card → child details
- "Atualizar agora" button (mock)

### 3. Map View (Responsável)
- Simple map with single pin
- NO routes or history
- Clear text: "Última atualização: há X min"

### 4. Create Alert
- Alert name (e.g., "Escola")
- Address field
- Map selection (mock)
- Expected time
- Save button
- Counter: "2 de 3 alertas usados"
- 4th alert triggers paywall state (mock)

### 5. History
- Simple timeline
- Today/Yesterday sections
- Events only:
  - Chegou (Arrived)
  - Saiu (Left)
  - Atrasou (Late)
  - Compartilhamento pausado (Sharing paused)

### 6. Child Main Screen
- Large text showing status
- Single button: Pausar/Retomar
- Trust message: "Seus responsáveis serão avisados"

### 7. Invite Screen
- Explanation text
- "Gerar link" button
- Simple, human language

### 8. Paywall (Mock)
- Clean visual
- No pressure tactics
- Clear benefits text
- Continue button

## Design Principles

**Mandatory UX Principles:**
- Extremely simple UX
- Few screens
- Neutral language (no alarmist tone)
- Always clear states
- "App for lazy people" - minimal interaction required

**Visual Style:**
- SwiftUI native components
- Neutral colors
- Clear typography
- Smooth animations
- Minimal icons
- Not cluttered

**Language Examples:**
✅ Correct: "João chegou na escola"
❌ Wrong: Alarmist or surveillance-like language

## Key Concepts (Not Yet Implemented)

### Location System
- No tracking - uses system geofencing only
- Map shows only last known location + timestamp
- Update interval: Fixed at 5 minutes (must be easily configurable via .env later)

### Authentication
- Invisible login using local UUID
- No manual registration in Phase 1
- Backend recognizes user by UUID

### Invites
- Universal link system
- Initial limits: 2 guardians, 10 children
- All guardians receive alerts for all children

### Monetization
- Paywall appears only when limits are reached
- Never block: critical alerts, precision, basic security
- Must be easily configurable in future

## Code Organization

### File Structure (Phase 2)
```
alert/
├── alertApp.swift                 # Main app entry point
├── ContentView.swift              # Main view with permission flow
├── Models.swift                   # Data models (Codable)
├── AppState.swift                 # Global state + LocationManager integration
├── LocationManager.swift          # Location & geofencing services
├── DataManager.swift              # Local persistence (UserDefaults)
├── LocationPermissionView.swift   # Permission explanation screen
├── HomeView.swift                 # Responsável home
├── ChildModeView.swift            # Criança mode (pause/resume)
├── ChildDetailView.swift          # Map with real location
├── CreateAlertView.swift          # Create alerts with geofences
├── AlertsView.swift               # Manage alerts
├── HistoryView.swift              # Event history
├── SplashView.swift               # Boot screen
├── InviteView.swift               # Invite screen (mock)
├── PaywallView.swift              # Paywall screen (mock)
├── AddChildView.swift             # Add child (mock)
├── PERMISSOES.md                  # Setup instructions
├── FASE2-COMPLETA.md              # Phase 2 summary
└── Assets.xcassets/               # App assets
```

### Phase 1 Implementation Guidelines

**DO:**
- Create all screen views as separate SwiftUI views
- Use mock data and @State for UI demonstrations
- Focus on navigation flow and UX
- Create reusable components
- Use clear, descriptive naming
- Add comments explaining intended future behavior

**DO NOT:**
- Add real location services
- Implement actual notifications
- Create backend API calls
- Add authentication logic
- Implement data persistence beyond in-memory state

## Success Criteria (Phase 1)	

✅ Clear flow between all screens
✅ Calm, anxiety-reducing UX
✅ Evident difference between guardian and child modes
✅ No real logic implemented
✅ Code organized to evolve into Phase 2

## Next Phases (After Phase 1 Approval)

- Phase 2: Permissions and location services
- Phase 3: Backend integration
- Phase 4: Real notifications
- Phase 5: Production features

⚠️ **Do not advance to next phases without explicit approval.**
