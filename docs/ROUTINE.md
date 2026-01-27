# Routine Copy (Morning + Night)

This document defines the copy used by the in-app routine flow (alarm screen,
verification prompts, and success states). It mirrors the structure of
NOTIFICATIONS.md so the UI can swap between morning and night variants and
later plug into localization.

---

## Principles

- **Short, actionable, calm**: minimize cognitive load.
- **Single intent** per screen.
- **Encouraging, not punitive**: no shame language.
- **Consistent structure**: the UI reads from a fixed schema.

---

## Copy Schema

Each routine provides the following fields:

### Alarm screen
- `pill`: short label above the hero (e.g. "Morning check-in")
- `title`: primary headline
- `body`: supporting line
- `ctaTitle`: main action (short)
- `ctaSubtitle`: helper line under CTA
- `skipLabel`: secondary action label

### Verification header
- `alarmBadge`: shown when alarm is active
- `title`: section headline
- `subtitle`: supporting line

### Success
- `title`: completion headline
- `subtitle`: short sendoff

### Method prompts (shared across routines)
- Manual
  - `alarmLabel`, `alarmHint`
  - `verifyHoldLabel`
- NFC
  - `alarmLabel`, `alarmHint`
  - `verifyScanningLabel`, `verifySimulateLabel`
- Selfie
  - `alarmLabel`, `alarmHint`
  - `verifyCameraLabel`, `verifyCaptureLabel`

---

## Morning Routine

**Alarm screen**
- pill: Morning check-in
- title: Wake up and brush
- body: Start the day with a real check-in to protect your streak.
- ctaTitle: I'm up
- ctaSubtitle: Start check-in
- skipLabel: Skip for now

**Verification header**
- alarmBadge: Alarm Active
- title: Brush check
- subtitle: Kick off the morning strong.

**Success**
- title: Morning complete!
- subtitle: Have a great day.

---

## Night Routine

**Alarm screen**
- pill: Bedtime check-in
- title: Brush before bed
- body: Close out the night with a real check-in.
- ctaTitle: I'm ready
- ctaSubtitle: Start check-in
- skipLabel: Skip for now

**Verification header**
- alarmBadge: Alarm Active
- title: Brush check
- subtitle: Let's finish the day strong.

**Success**
- title: Tonight complete!
- subtitle: Sleep well.

---

## Method Prompts (shared)

**Manual**
- alarmLabel: Hold to verify
- alarmHint: Keep pressure steady until it completes.
- verifyHoldLabel: Hold

**NFC**
- alarmLabel: Tap your tag
- alarmHint: Hold your device near the NFC tag.
- verifyScanningLabel: Scanning for tag...
- verifySimulateLabel: (Simulate Tap)

**Selfie**
- alarmLabel: Take a selfie
- alarmHint: Frame your face inside the guide.
- verifyCameraLabel: Simulating Camera...
- verifyCaptureLabel: Take Photo
