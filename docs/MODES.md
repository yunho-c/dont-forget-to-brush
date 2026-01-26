# Modes: Concrete Rules

This document defines **implementation-grade** rules for the three modes.
It is intentionally explicit so engineering can build without interpretation.

---

## Definitions

- **Night**: The bedtime window anchored to `bedtimeStart` for a given local date.
- **Window**: `[bedtimeStart, bedtimeEnd]`. If `bedtimeEnd` is earlier than
  `bedtimeStart`, the window crosses midnight.
- **Early completion**: A brush completed up to **3 hours** before
  `bedtimeStart` counts for the upcoming night.
- **On-time completion**: Completed inside the window.
- **Late completion**: Completed after `bedtimeEnd` but within the mode's grace.
- **Missed**: No completion by grace end; streak resets.
- **Verification**: The selected method (manual hold, NFC, selfie).

---

## Global rules (all modes)

1. A completion only counts **once per night**.
2. If multiple completions exist in one night, keep the **earliest**.
3. Streak increments on **on-time** or **late** completion, unless specified.
4. If an **alarm is active**, completion must use **verification**.
5. If the user changes bedtime window, apply changes **starting next night**.

---

## Mode summary (default values)

| Mode | Reminders | Alarm | Snooze | Grace | Verification |
| --- | --- | --- | --- | --- | --- |
| **Gentle** | 3 reminders max | None | N/A | 4h | Optional |
| **Accountability** | Persistent reminders | After window end | 2 × 5 min | 1h | Required if alarm |
| **No Excuses** | Persistent + escalation | At window start | 1 × 3 min | 0h | Required |

---

## Gentle

**Goal**: Encourage habit without stress. No alarms.

**Rules**
- **Reminders**: At `bedtimeStart`, then +45 min, then +90 min (max 3).
- **Sleep Mode**: Pause reminders for **90 minutes**, then send one gentle
  reminder. Do not repeat after that.
- **Completion**:
  - **Early**: up to 3 hours before `bedtimeStart` counts.
  - **On-time**: within window counts.
  - **Late**: within **4 hours** after `bedtimeEnd` counts and keeps streak.
  - **Missed**: no completion by grace end resets streak.
- **Verification**: Optional. If the user taps **Brush Now**, allow instant
  confirmation without verification (no alarms in Gentle).

---

## Accountability

**Goal**: Encourage follow-through with persistent reminders and a light alarm.

**Rules**
- **Reminders**: At `bedtimeStart`, then every **30 minutes** until completion
  or window end.
- **Escalation**: If not completed **60 minutes** after `bedtimeStart`, switch
  to a **persistent notification** (cannot be swiped away).
- **Alarm**: If not completed by `bedtimeEnd`, trigger alarm with sound and
  full-screen overlay.
- **Snooze**: Up to **2 snoozes of 5 minutes** each. After that, alarm persists
  until verification.
- **Completion**:
  - **Early**: up to 3 hours before `bedtimeStart` counts.
  - **On-time**: within window counts.
  - **Late**: within **1 hour** after `bedtimeEnd` counts and keeps streak,
    but **mark session as late**.
  - **Missed**: no completion by grace end resets streak.
- **Verification**:
  - Required if alarm is active.
  - Optional before alarm.

---

## No Excuses

**Goal**: Enforce completion with minimal escape hatches.

**Rules**
- **Reminders**: At `bedtimeStart`, then every **20 minutes** until completion.
- **Alarm**: If not completed **at `bedtimeStart`**, start alarm immediately.
  Alarm is full-screen and sticky.
- **Snooze**: Single **3-minute** snooze allowed. After that, alarm persists.
- **Completion**:
  - **Early**: up to 3 hours before `bedtimeStart` counts.
  - **On-time**: within window counts.
  - **Late**: **no grace period**. Completion after `bedtimeEnd` does not count
    for streak and starts a new streak if done the next night.
  - **Missed**: if window ends without completion, streak resets.
- **Verification**: **Always required**, even before alarm.
- **Dismissal**: Alarm cannot be dismissed without verification.

---

## UX guidance (non-functional but required)

- All time comparisons use **local time**.
- If the device is offline, schedule locally and reconcile on resume.
- If permissions are denied, show a blocking prompt and fall back:
  - **Gentle**: continue without reminders.
  - **Accountability / No Excuses**: warn that alarms will not function and
    disable mode selection until permissions are granted.
