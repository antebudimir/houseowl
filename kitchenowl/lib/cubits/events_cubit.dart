import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/event.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/event.dart';

class EventsCubit extends Cubit<EventsCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;
  Future<void>? _refreshThread;

  EventsCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        super(const LoadingEventsCubitState()) {
    refresh();
    ApiService.getInstance().onEventUpdate(onEventUpdate);
  }

  EventsCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        super(const LoadingEventsCubitState()) {
    refresh();
  }

  void onEventUpdate(dynamic data) {
    refresh();
  }

  Future<bool> addEvent(Event event) async {
    final res = await _transactionHandler.runTransaction(
      TransactionEventAdd(household: household, event: event),
    );
    await refresh();

    return res;
  }

  Future<bool> updateEvent(Event event) async {
    final res = await _transactionHandler.runTransaction(
      TransactionEventUpdate(event: event),
    );
    await refresh();

    return res;
  }

  Future<bool> deleteEvent(Event event) async {
    final res = await _transactionHandler.runTransaction(
      TransactionEventRemove(event: event),
    );
    await refresh();

    return res;
  }

  Future<void> refresh() {
    if (_refreshThread == null) {
      _refreshThread = _refresh();
    }

    return _refreshThread!;
  }

  Future<void> _refresh() async {
    final events = await _transactionHandler.runTransaction(
      TransactionEventsGet(household: household),
    );
    if (_refreshThread != null) {
      emit(ListEventsCubitState(events: events));
      _refreshThread = null;
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offEventUpdate(onEventUpdate);
    super.close();
  }
}

abstract class EventsCubitState extends Equatable {
  const EventsCubitState();

  List<Event> get events;

  @override
  List<Object?> get props => [];
}

class LoadingEventsCubitState extends EventsCubitState {
  const LoadingEventsCubitState();

  @override
  List<Event> get events => const [];
}

class ListEventsCubitState extends EventsCubitState {
  final List<Event> events;

  const ListEventsCubitState({this.events = const []});

  @override
  List<Object?> get props => <Object?>[...events];
}
