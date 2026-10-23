import 'dart:convert';

import 'package:kitchenowl/models/event.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension EventApi on ApiService {
  String eventRoute({Household? household, Event? event}) =>
      "${household != null ? householdPath(household) : ""}/event${event?.id != null ? "/${event!.id}" : ""}";

  Future<List<Event>?> getEvents(Household household) async {
    final res = await get(eventRoute(household: household));
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => Event.fromJson(e))
        .toList();
  }

  Future<Event?> addEvent(Household household, Event event) async {
    final res = await post(
      eventRoute(household: household),
      jsonEncode(event.toJson()),
    );
    if (res.statusCode != 200) return null;

    return Event.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateEvent(Event event) async {
    final res = await post(
      eventRoute(event: event),
      jsonEncode(event.toJsonWithId()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteEvent(Event event) async {
    final res = await delete(eventRoute(event: event));

    return res.statusCode == 200;
  }

  /// Live pre-check for the form's conflict banner. Returns the conflicting
  /// events for any of [attendeeIds] overlapping [start]..[end), or null on
  /// connection failure. The server re-checks authoritatively on save.
  Future<List<Event>?> getEventConflicts(
    Household household, {
    required DateTime start,
    required DateTime end,
    required List<int?> attendeeIds,
  }) async {
    final ids = attendeeIds.whereType<int>().toList();
    final query =
        "?start=${start.millisecondsSinceEpoch}&end=${end.millisecondsSinceEpoch}" +
            ids.map((id) => "&attendee=$id").join();
    final res = await get("${eventRoute(household: household)}/conflicts$query");
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => Event.fromJson(e))
        .toList();
  }

  void onEventUpdate(dynamic Function(dynamic) handler) {
    socket.on("event:update", handler);
  }

  void offEventUpdate(dynamic Function(dynamic) handler) {
    socket.off("event:update", handler);
  }
}
