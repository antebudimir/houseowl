import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/planned_buy.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/planned_buy.dart';

class PlannedBuysCubit extends Cubit<PlannedBuysCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;
  Future<void>? _refreshThread;

  PlannedBuysCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        super(const LoadingPlannedBuysCubitState()) {
    refresh();
    ApiService.getInstance().onPlannedBuyUpdate(onPlannedBuyUpdate);
  }

  PlannedBuysCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        super(const LoadingPlannedBuysCubitState()) {
    refresh();
  }

  void onPlannedBuyUpdate(dynamic data) {
    refresh();
  }

  Future<bool> addPlannedBuy(PlannedBuy plannedBuy) async {
    final res = await _transactionHandler.runTransaction(
      TransactionPlannedBuyAdd(household: household, plannedBuy: plannedBuy),
    );
    await refresh();

    return res;
  }

  Future<bool> updatePlannedBuy(PlannedBuy plannedBuy) async {
    final res = await _transactionHandler.runTransaction(
      TransactionPlannedBuyUpdate(plannedBuy: plannedBuy),
    );
    await refresh();

    return res;
  }

  Future<bool> deletePlannedBuy(PlannedBuy plannedBuy) async {
    final res = await _transactionHandler.runTransaction(
      TransactionPlannedBuyRemove(plannedBuy: plannedBuy),
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
    final buys = await _transactionHandler.runTransaction(
      TransactionPlannedBuysGet(household: household),
    );
    if (_refreshThread != null) {
      emit(ListPlannedBuysCubitState(buys: buys));
      _refreshThread = null;
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offPlannedBuyUpdate(onPlannedBuyUpdate);
    super.close();
  }
}

abstract class PlannedBuysCubitState extends Equatable {
  const PlannedBuysCubitState();

  List<PlannedBuy> get buys;

  @override
  List<Object?> get props => [];
}

class LoadingPlannedBuysCubitState extends PlannedBuysCubitState {
  const LoadingPlannedBuysCubitState();

  @override
  List<PlannedBuy> get buys => const [];
}

class ListPlannedBuysCubitState extends PlannedBuysCubitState {
  final List<PlannedBuy> buys;

  const ListPlannedBuysCubitState({this.buys = const []});

  @override
  List<Object?> get props => <Object?>[...buys];
}
