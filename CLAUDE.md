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

<!-- cce-block-version: 4 -->
## Context Engine (CCE)

This project uses Code Context Engine for intelligent code retrieval and
cross-session memory.

### Searching the codebase

**You MUST use `context_search` instead of reading files directly** when
exploring the codebase, answering questions about code, or understanding how
things work. This is a hard requirement, not a suggestion. `context_search`
returns the most relevant code chunks with confidence scores instead of whole
files, and tracks token savings automatically.

When to use `context_search`:
- Answering questions about the codebase ("how does X work?", "where is Y?")
- Exploring structure or architecture
- Finding related code, functions, or patterns
- Any time you would otherwise read a file just to understand it

When to use `Read` instead:
- You need to edit a specific file (read before editing)
- You need the exact, complete content of a known file path

Other search tools:
- `expand_chunk` — get full source for a compressed result
- `related_context` — find what calls/imports a function

### Cross-session memory — use it actively

This project has persistent memory across Claude Code sessions. **You must
use it both ways: recall before answering, record after deciding.** Memory
that is not recorded is lost; memory that is not recalled does nothing.

**Before answering a non-trivial question, call `session_recall`.**
Especially when:
- The question touches architecture, design, or naming choices
- The user asks "what / why / how did we ..."
- You are about to recommend an approach the team may have already chosen
  or already rejected

Pass a topic phrase, not a single word — e.g. `session_recall("auth flow")`,
not `session_recall("auth")`. Recall is vector-similarity-based, so paraphrases
match. If recall returns relevant entries, lead with them ("Per a prior
decision: ...") instead of re-deriving the answer.

**After making a non-obvious decision, call `record_decision`.** Especially:
- Choosing one library / pattern / approach over another
- Resolving an ambiguity in the spec or requirements
- Establishing a convention the project should follow going forward
- Anything you would not want to re-litigate next session

Format: `record_decision(decision="...", reason="...")`. Keep both fields
short and specific — they are surfaced verbatim at the start of future
sessions.

**After meaningful work in a file, call `record_code_area`.** Especially when:
- You added or substantially modified a function/class
- You traced through a non-obvious flow and want future-you to find it fast

Format: `record_code_area(file_path="...", description="...")`.

Skip recording for trivial reads, formatting changes, or one-off lookups —
the goal is durable signal, not an event log.

### Drilling deeper from a recall hit

`session_recall` results are tagged with the source session id, e.g.
`[turn sid:abc123|n:5]`. To drill in:

- `session_timeline(session_id="abc123")` — walk the per-turn summaries of
  that session in order. Use this when the user asks "what was the
  reasoning?" or "how did we get there?".
- `session_event(event_id=N)` — fetch a specific tool event's raw input
  and output (capped at 4 KB at read time). Use this when a turn summary
  references a tool result you actually need to inspect.

Both are read-only and cheap. Prefer them over re-running tool calls or
asking the user to re-paste context.

### Output style

Respond in compressed style. Drop articles (a, an, the) in prose. Use
sentence fragments over full sentences. Use short synonyms (fix not resolve,
check not investigate). Pattern: [thing] [action] [reason]. [next step].
No filler, hedging, pleasantries, trailing summaries, or restating what
the user said. One sentence if one sentence is enough.

When suggesting code changes, show only the changed lines with 3 lines of
context. Never rewrite entire files. Multiple changes in one file: show each
change separately. Never echo back unchanged code the user already has.

Code blocks, file paths, commands, error messages: always written in full.
Security warnings and destructive action confirmations: use full clarity.
<!-- /cce-block -->
