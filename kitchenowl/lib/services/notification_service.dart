import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show WidgetsBinding;
// `Person` collides with our model of the same name; the plugin's Android
// person type is unused here.
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:houseowl/gen/l10n/app_localizations.dart';
import 'package:houseowl/models/event.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/models/task.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules on-device reminders for events, tasks and birthdays.
///
/// Delivery is purely local: the OS fires the notification at the scheduled
/// instant, so there is no Firebase / Play Services dependency and reminders
/// keep working offline once they have been scheduled. Whenever the relevant
/// data refreshes, the owning cubit re-syncs the schedule so edits, deletes
/// and completions are reflected.
///
/// Supported on Android and iOS only; on web and desktop every call is a
/// no-op so the rest of the app is unaffected.
class NotificationService {
  static NotificationService? _instance;

  /// Notification-id ranges keep the three kinds independent so cancelling
  /// one kind's stale reminders never touches another's.
  static const int _eventBase = 100000000;
  static const int _taskBase = 200000000;
  static const int _birthdayBase = 300000000;
  static const int _span = 1000000;

  static const String _eventChannelId = 'event_reminders';
  static const String _taskChannelId = 'task_reminders';
  static const String _birthdayChannelId = 'birthday_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initFuture;
  bool _supported = false;

  NotificationService._();

  static NotificationService getInstance() =>
      _instance ??= NotificationService._();

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initialises the plugin, creates the Android channels and requests
  /// permission. Safe to call repeatedly and concurrently.
  Future<void> init() {
    if (!isSupported) return Future.value();
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _eventChannelId,
          'Event reminders',
          description: 'Notifications before an event starts',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _taskChannelId,
          'Task reminders',
          description: 'Notifications before a task is due',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _birthdayChannelId,
          'Birthdays',
          description: 'Notifications on the day of a birthday',
          importance: Importance.defaultImportance,
        ),
      );
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _supported = true;
  }

  Future<AppLocalizations> _loc() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return AppLocalizations.delegate.load(locale);
  }

  int _id(int base, int? entityId) => base + ((entityId ?? 0) % _span);

  /// Cancels every pending notification in [base] .. [base] + [_span).
  Future<void> _cancelRange(int base) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= base && request.id < base + _span) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required DateTime when,
    required Importance importance,
  }) async {
    // Inexact scheduling avoids the exact-alarm permission on Android 12+;
    // household reminders tolerate a few minutes of slack.
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: importance,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Replaces the scheduled event reminders with the given set.
  Future<void> syncEvents(List<Event> events) async {
    if (!isSupported) return;
    await init();
    if (!_supported) return;

    final loc = await _loc();
    await _cancelRange(_eventBase);
    final now = DateTime.now();
    for (final event in events) {
      final lead = event.reminderMinutes;
      if (lead == null || event.id == null) continue;
      final when = event.start.toLocal().subtract(Duration(minutes: lead));
      if (!when.isAfter(now)) continue;

      await _schedule(
        id: _id(_eventBase, event.id),
        channelId: _eventChannelId,
        title: event.name,
        body: loc.reminderEventBody(DateFormat.jm().format(when)),
        when: when,
        importance: Importance.high,
      );
    }
  }

  /// Replaces the scheduled task reminders with the given set. Open tasks
  /// with a due date and a lead time are anchored at 09:00 local on the due
  /// date, then offset by the lead time.
  Future<void> syncTasks(List<Task> tasks) async {
    if (!isSupported) return;
    await init();
    if (!_supported) return;

    final loc = await _loc();
    await _cancelRange(_taskBase);
    final now = DateTime.now();
    for (final task in tasks) {
      final lead = task.reminderMinutes;
      final due = task.dueDate;
      if (lead == null || due == null || task.id == null || task.isDone) {
        continue;
      }
      final dueAt = DateTime(due.year, due.month, due.day, 9);
      final when = dueAt.subtract(Duration(minutes: lead));
      if (!when.isAfter(now)) continue;

      await _schedule(
        id: _id(_taskBase, task.id),
        channelId: _taskChannelId,
        title: task.name,
        body: loc.reminderTaskBody(DateFormat.yMMMd().format(due)),
        when: when,
        importance: Importance.high,
      );
    }
  }

  /// Schedules a 09:00 local reminder for each person's next birthday.
  Future<void> syncBirthdays(List<Person> persons) async {
    if (!isSupported) return;
    await init();
    if (!_supported) return;

    final loc = await _loc();
    await _cancelRange(_birthdayBase);
    final now = DateTime.now();
    for (final person in persons) {
      final occurrence = person.nextBirthdayOccurrence(now);
      if (occurrence == null || person.id == null) continue;
      final when = DateTime(
        occurrence.year,
        occurrence.month,
        occurrence.day,
        9,
      );
      if (!when.isAfter(now)) continue;

      await _schedule(
        id: _id(_birthdayBase, person.id),
        channelId: _birthdayChannelId,
        title: person.name,
        body: loc.reminderBirthdayBody,
        when: when,
        importance: Importance.defaultImportance,
      );
    }
  }
}
