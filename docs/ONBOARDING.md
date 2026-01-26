# Onboarding Requirements (Relaxed Defaults)

This document defines a low-friction onboarding flow. All steps are optional.
If the user skips or leaves fields blank, the app must fall back to sensible
defaults and continue.

---

## Goals

- Minimize friction: no required fields.
- Never block completion because of missing input.
- Always produce a valid configuration.

---

## Defaults (used when input is missing)

- **Name**: `"Friend"`
- **Bedtime window**: `22:00–01:00`
- **Mode**: `Accountability`
- **Verification method**: `Manual`

---

## Step requirements

### 1) Welcome
- No inputs required.
- Primary action: **Continue**.

### 2) Name (optional)
- Input can be empty.
- If empty, use default `"Friend"`.

### 3) Bedtime window (optional)
- If user does not set a time, use `22:00–01:00`.
- If only a start time is set, keep end at default `01:00`.
- If only an end time is set, keep start at default `22:00`.
- If end is earlier than start, treat as crossing midnight.

### 4) Mode (optional)
- If not chosen, use **Accountability**.

### 5) Verification method (optional)
- If not chosen, use **Manual**.

---

## Completion rules

- The user can finish onboarding without completing any steps.
- The app must call `completeOnboarding(...)` with defaults filled in.
- The app should allow re-entry to onboarding from Settings.

---

## UX notes

- Use gentle language: “You can skip this for now.”
- Show defaults in the UI (as placeholders or preselected values).
- Avoid error states for empty input.
