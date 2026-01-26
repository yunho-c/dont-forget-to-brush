# Production Readiness TODOs

This document captures the concrete work needed to ship a production-grade app.

---

## 1) Product & UX
- [x] Finalize requirements for onboarding, habit rules, and success/late definitions.
- [ ] Create full state designs: permissions denied, no-network, empty history, error states.
- [ ] Define copy and microcopy:
  - [x] Reminders + alarms.
  - [ ] Verification + failure states.

---

## 2) Core Features
- [x] Implement real scheduling: bedtime window, reminders, and alarms.
- [ ] Implement verification methods:
  - [ ] Manual hold with failure handling.
  - [ ] NFC tag scan + tag registration flow.
  - [ ] Selfie check (camera + optional ML/face detection).
- [ ] Implement streak logic with timezone awareness and missed-day recovery rules.

---

## 3) Platform Integration
- [ ] Local notifications:
  - [x] Android notification channels.
  - [x] iOS/macOS time-sensitive capability + payloads.
  - [x] Permission request flows.
- [ ] Background execution:
  - [ ] iOS background tasks, Android foreground services as needed.
- [ ] Device integrations:
  - [ ] NFC, camera, storage, haptics.

---

## 4) Data & State
- [x] Move sessions/history to a real DB (e.g., Drift/SQLite).
- [x] Add data models for sessions.
- [ ] Add data models for reminders and alarms.
- [ ] Sync strategy (optional):
  - [ ] Account + cloud backup.
  - [ ] Multi-device reconciliation.

---

## 5) Security & Privacy
- [ ] Privacy policy and consent flows.
- [ ] Secure storage for sensitive data (Keychain/Keystore).
- [ ] Data export/delete and opt-out controls.

---

## 6) Testing & Quality
- [ ] Unit tests for time math + streak logic.
- [ ] Widget tests for critical flows.
- [ ] Integration tests for reminders/alarms and permissions.
- [ ] Crash reporting and analytics hooks.

---

## 7) Release & Ops
- [ ] CI/CD with signing, versioning, and store builds.
- [ ] App Store / Play Store compliance and review readiness.
- [ ] Monitoring, alerts, and performance profiling.
