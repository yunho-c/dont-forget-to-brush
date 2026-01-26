# Notifications & Alarms (Copy + Rules Template)

This document defines a production-ready template for notification and alarm
messaging. It includes copy, timing guidance, and UX rules by mode — using
plain, human language in user-facing text.

---

## Principles

- **Short, actionable, calm**: The message should reduce friction.
- **Single intent** per notification (no mixed prompts).
- **Time-aware**: Copy reflects timing (start vs late).
- **No shame**: Avoid guilt-heavy language.
- **Consistency**: Titles and tones follow a predictable pattern.

---

## Naming conventions

- **Title**: 1–3 words, always a verb or status.
- **Body**: 1 short sentence, 50–70 chars when possible.
- **CTA**: defaults to **Open app** (no custom action unless supported).

---

## Notification templates

### Gentle (reminders only)

**At your usual time**
- Title: **Brush now**
- Body: *Take 90 seconds and you’re done for the night.*

**A little later**
- Title: **Quick reminder**
- Body: *You still have time tonight.*

**Last nudge**
- Title: **Last nudge**
- Body: *One quick brush and you can fully relax.*

### Accountability (persistent reminders + alarm)

**At your usual time**
- Title: **Brush now**
- Body: *Keep the streak going tonight.*

**Keeps showing**
- Title: **Still time**
- Body: *Brush before the night is over.*

**Alarm**
- Title: **Brush required**
- Body: *Brush to silence this.*

### No Excuses (alarm + persistent reminders)

**Alarm**
- Title: **Brush now**
- Body: *Brush to silence this.*

**Reminder (if used before alarm)**
- Title: **Do it now**
- Body: *This is the only chance tonight.*

---

## Alarm behaviors

- **Full-screen** where supported.
- **High priority** with sound and vibration.
- **Stop requires brushing** (per mode rules).
- **Snooze** uses mode-specific timing.

---

## Escalation rules by mode (summary)

| Mode | Reminder cadence | Persistent? | Alarm trigger | Snooze |
| --- | --- | --- | --- | --- |
| Gentle | Start +45 +90 | No | None | N/A |
| Accountability | Every 30 min | After 60 min | End of night | 2 × 5 min |
| No Excuses | Every 20 min | Immediate | Usual time | 1 × 3 min |

---

## Message variants (optional A/B)

Keep a small pool to avoid repetition. Rotate daily.

**Variant pool**
- *Take 90 seconds and you’re done for the night.*
- *Brush now, then fully unwind.*
- *A quick brush beats a rushed morning.*
- *Keep the streak alive tonight.*
- *Small win, big sleep.*

---

## Failure & recovery states

**Missed night**
- Title: **Window missed**
- Body: *Tomorrow is a fresh start.*

**Late completion (if grace applies)**
- Title: **Late, but counted**
- Body: *Nice recovery — streak intact.*

---

## UX requirements

- Notifications must respect **Do Not Disturb** where required by OS.
- If permission is denied, show a single in-app banner with a settings link.
- Keep badge counts off by default (avoid notification fatigue).
