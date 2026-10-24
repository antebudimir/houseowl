import 'package:houseowl/models/event.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction.dart';

/// Events are online-only: there is no offline cache, mirroring task
/// transactions.
class TransactionEventsGet extends Transaction<List<Event>> {
  final Household household;

  TransactionEventsGet({
    required this.household,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionEventsGet",
        );

  @override
  Future<List<Event>> runLocal() async => [];

  @override
  Future<List<Event>> runOnline() async =>
      await ApiService.getInstance().getEvents(household) ?? [];
}

class TransactionEventAdd extends Transaction<bool> {
  final Household household;
  final Event event;

  TransactionEventAdd({
    required this.household,
    required this.event,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionEventAdd",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() async =>
      await ApiService.getInstance().addEvent(household, event) != null;
}

class TransactionEventUpdate extends Transaction<bool> {
  final Event event;

  TransactionEventUpdate({
    required this.event,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionEventUpdate",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() => ApiService.getInstance().updateEvent(event);
}

class TransactionEventRemove extends Transaction<bool> {
  final Event event;

  TransactionEventRemove({
    required this.event,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionEventRemove",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() => ApiService.getInstance().deleteEvent(event);
}
