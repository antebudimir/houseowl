# HouseOwl — Feature Plan: Reminders, Birthdays, Tasks, Loyalty Cards

Status: **implemented** (see the commit map at the end). This document keeps
the original analysis — feasibility, ranked options, data-model and UX
implications, file lists, effort and acceptance criteria — plus the approach
that was actually chosen and why.

## Guiding constraints

- **Google-free.** No Firebase, no Google Play Services. Reminders must be
  delivered without FCM.
- **Offline-first.** Reminders should keep working once scheduled, even
  without a network connection.
- **No feature flags.** Every shipped feature is unconditional.
- **Cherry-pickable fork.** Prefer isolated, additive changes over edits to
  shared upstream code.

## Shared reminder architecture (all reminder features)

Rather than a server push channel (which would require FCM and break the
Google-free rule), reminders are **scheduled on-device by the client** with
`flutter_local_notifications`. The OS fires the notification at the scheduled
instant, so it works when the app is closed and keeps working offline.

```
Event/Task/Person data refresh (cubit)
   → NotificationService.sync*()  (detached, best-effort)
   → cancel stale notifications for that kind
   → schedule OS-level local notifications for future items
```

The server only stores the reminder preference; it never pushes. This keeps
the backend simple, avoids a new table, and removes the "app must be
connected when the reminder fires" failure mode of a Socket.IO push design.

- Notification-id ranges keep the three kinds independent:
  events `100000000+`, tasks `200000000+`, birthdays `300000000+`.
- Android gets three channels (events/tasks/birthdays); the boot receiver
  restores scheduled reminders after a reboot.
- Scheduling is `inexactAllowWhileIdle` to avoid the Android 12+ exact-alarm
  permission; household reminders tolerate a few minutes of slack.
- Web and desktop are no-ops.

### Tradeoffs of going Google-free

- ✅ No Google account, works on de-Googled Android, better privacy.
- ❌ No server-to-device push while the app has never synced; a reminder is
  only scheduled once the relevant data has loaded on the device. For a
  household app this is acceptable.

---

## 1. Events reminder

### Feasibility
**Implementable.** The scheduler/model/UI chassis already existed; only a
reminder field, a picker, and local scheduling were missing.

### Options (ranked)
1. **Client-scheduled local notifications (chosen).** Store a lead time on
   the event; the client schedules a local notification on refresh.
2. **Server job + Socket.IO push.** APScheduler job emits a `reminder` event
   to the household room. Works only while a client is connected — rejected.
3. **Email reminder.** Reuses the mail stack but is not a push and needs a
   verified address.

### Recommended approach + rationale
Option 1. It is Google-free, offline-capable, needs no new table, and reuses
the existing event refresh path. Precise delivery does not require the server
to know device time zones.

### Data model
- `event.reminder_minutes INTEGER NULL` — minutes before `start`; `NULL` = no
  reminder. Serialized automatically by `obj_to_dict`.
- Migration adds the column via batch mode (SQLite-safe).

### UI/UX
- Reminder picker in the event add/edit form: No reminder / At time / 15 min /
  1 hour / 1 day / 1 week before.
- The chosen lead time appears in the calendar agenda subtitle.

### Integration points
- `EventsCubit._refresh` calls `NotificationService.syncEvents(events)`.

### Files
- Backend: `models/event.py`, `controller/event/schemas.py`,
  `controller/event/event_controller.py`,
  `migrations/versions/c3f1a9b2d4e6_add_reminder_minutes.py`,
  `tests/api/test_api_event.py`.
- Client: `models/event.dart`,
  `pages/household_page/event_add_update_page.dart`,
  `pages/household_page/events_page.dart`, `widgets/reminder_picker.dart`,
  `cubits/events_cubit.dart`, `l10n/app_en.arb`.

### Effort
~5–7 days (mostly the notification service, shared with the other features).

### Acceptance criteria
- [x] A lead time can be set when creating/editing an event.
- [x] A local notification fires at the configured time before the event.
- [x] Clearing the reminder removes the scheduled notification.
- [x] Editing an event reschedules its reminder.
- [x] No Firebase/Play Services; offline-capable.

---

## 2. Birthdays

### Feasibility
**Implementable.** Persons already store a birthday and the Birthdays view
already computes the next occurrence (recurring by construction — only the
month/day matter, with a sentinel year for "unknown"). The only gap was
reminders.

### Options (ranked)
1. **Reuse the client reminder system (chosen).** Schedule a 09:00 local
   notification for each person's next birthday from the persons cubit.
2. **Dedicated birthday reminder table/job.** Duplicates infrastructure.
3. **List-only (status quo).** No reminders — the documented limitation.

### Recommended approach + rationale
Option 1. Birthdays are inherently recurring and already computed on the
client; a daily 09:00 local notification needs no backend work at all.

### Data model
- No schema change. `person.birthday` (date) already exists; the sentinel year
  `1990` marks "year unknown" and is never shown as an age.

### UI/UX
- Birthdays view keeps its "Upcoming in the next 30 days" grouping.
- People with a known birth year show "Turns {age}".
- A reminder fires at 09:00 on the day.

### Integration points
- `PersonsCubit._refresh` (full list only, not search subsets) calls
  `NotificationService.syncBirthdays(persons)`.

### Files
- Client: `pages/household_page/birthdays_page.dart`,
  `cubits/persons_cubit.dart`, `services/notification_service.dart`,
  `l10n/app_en.arb`, `test/widgets/birthdays_page_test.dart`.

### Effort
~3–4 days (after the shared reminder service exists).

### Acceptance criteria
- [x] A local notification fires at 09:00 on a person's birthday.
- [x] Age is shown when the birth year is known.
- [x] People without a birthday are unaffected.
- [x] No Firebase/Play Services; offline-capable.

---

## 3. Tasks

### Feasibility
**Fully implementable.** The task model already supports due date, priority,
recurrence, assignee, tags, completion and planned-buy links. Gaps were
reminders and list filtering/sorting.

### Options (ranked)
1. **Reminders + filter/sort, keep date-only due dates (chosen).**
2. **Add a time-of-day to due dates.** High-risk migration; timezone/DST
   complexity in recurrence math; users currently prefer simple dates.
3. **Filter/sort only.** Improves scanning but stays passive.

### Recommended approach + rationale
Option 1. Date-only due dates are intentional and keep recurrence math
timezone-free; the filter/sort UI addresses the "too many tasks" problem and
reminders address "forgot about it". Reminders reuse the shared service.

### Data model
- `task.reminder_minutes INTEGER NULL` — minutes before the due date; the
  client anchors at 09:00 local on the due date. Recurring successors inherit
  the value (`Task.complete()` copies it).
- Migration adds the column via batch mode.

### UI/UX
- Reminder picker appears once a due date is set; clearing the due date
  clears the reminder.
- Filter bar: sort by due date / priority / name; filter by assignee or tag;
  clear button. Undated tasks sort last. Open/completed grouping is kept.

### Integration points
- `TasksCubit._refresh` calls `NotificationService.syncTasks(tasks)`.
- Filtering/sorting is client-side over the loaded list (no new requests).

### Files
- Backend: `models/task.py`, `controller/task/schemas.py`,
  `controller/task/task_controller.py`, the reminder migration,
  `tests/api/test_api_task.py`.
- Client: `models/task.dart`, `pages/household_page/task_add_update_page.dart`,
  `pages/household_page/tasks_page.dart`, `cubits/tasks_cubit.dart`,
  `widgets/reminder_picker.dart`, `l10n/app_en.arb`,
  `test/widgets/tasks_page_test.dart`.

### Effort
~8–10 days.

### Acceptance criteria
- [x] Sort by due date (ascending, undated last), priority (descending) or
      name.
- [x] Filter by assignee and by tag; clear button resets.
- [x] A reminder fires before the due date when one is set.
- [x] Recurring tasks carry the reminder to the next occurrence.
- [x] Covered by backend and widget tests.


---

## 4. Loyalty cards (larger, Catima-style display)

### Feasibility
**Fully implementable.** UI-only. The barcode renderer (`barcode_widget`),
wakelock and data model already exist; no backend change.

### Options (ranked)
1. **Full, responsive card (chosen).** Store name + large barcode filling the
   width, card number large/selectable, matrix codes square.
2. **Simply enlarge the existing barcode box.** Minimal but does not achieve
   the "card" look.
3. **Catima parity (wallet grid, colours, images).** Scope creep; needs
   backend storage for preferences.

### Recommended approach + rationale
Option 1. It delivers the requested "larger card" within the existing
dependencies, keeps the black-on-white quiet zone for scanning, and handles
1D vs 2D geometry correctly.

### Data model
- None. `store_name`, `card_number`, `barcode_format`, `notes` already exist.

### UI/UX
- Responsive width (capped at 560dp), square matrix codes, 1D codes stretched.
- Wakelock keeps the screen on while viewing.
- The white quiet-zone container and black-on-white contrast are preserved in
  both light and dark themes.

### Integration points
- `BarcodeFormat.isMatrix` classifies QR/Aztec/Data Matrix as square.

### Files
- Client: `pages/household_page/loyalty_card_page.dart`,
  `enums/barcode_format_enum.dart`,
  `test/enums/barcode_format_sync_test.dart`.

### Effort
~3–4 days.

### Acceptance criteria
- [x] The barcode fills the card width and remains scannable.
- [x] QR/Aztec/Data Matrix render square; 1D codes stretch.
- [x] Store name and a large, selectable card number are shown.
- [x] Dark mode keeps full contrast (white barcode panel).
- [x] No layout overflow on phone widths; capped on wide screens.

---

## Atomic commit map

Each feature landed as small, independently reviewable commits:

1. `feat(backend): store reminder lead time on events and tasks` —
   model + schema + controller + migration + API tests.
2. `feat(client): carry reminder lead time on event and task models` —
   model round-tripping.
3. `feat(client): schedule on-device reminders via local notifications` —
   dependency, `NotificationService`, cubit wiring, Android channels/receivers.
4. `feat(client): let users set event and task reminders` —
   `ReminderPicker`, forms, list indicators, widget test, changelog.
5. `feat(client): birthday reminders and age display` —
   age line, widget test, changelog.
6. `feat(client): filter and sort the task list` —
   filter bar, widget test, changelog.
7. `feat(client): enlarge the loyalty card for scanning` —
   responsive card, `isMatrix`, enum test, changelog.

## Verification (gates run for this work)

- Backend: `uv run pytest` (full suite) — green.
- Migrations: fresh DB base → head replays; downgrade then upgrade verified;
  a single head (`c3f1a9b2d4e6`).
- Client: `flutter gen-l10n`, `flutter analyze` (no issues),
  `flutter test` (all green).
- Guards: `scripts/check_theme_imports.sh` and the
  `firebase|play-services` lockfile check both pass.

