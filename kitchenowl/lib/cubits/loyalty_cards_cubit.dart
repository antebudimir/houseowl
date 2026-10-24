import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/loyalty_card.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/loyalty_card.dart';

class LoyaltyCardsCubit extends Cubit<LoyaltyCardsCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;
  List<LoyaltyCard> cardList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  LoyaltyCardsCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        super(const LoadingLoyaltyCardsCubitState()) {
    refresh();
    ApiService.getInstance().onLoyaltyCardUpdate(onLoyaltyCardUpdate);
  }

  LoyaltyCardsCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        super(const LoadingLoyaltyCardsCubitState()) {
    refresh();
  }

  String get query => (state is SearchLoyaltyCardsCubitState)
      ? (state as SearchLoyaltyCardsCubitState).query
      : "";

  void onLoyaltyCardUpdate(dynamic data) {
    refresh();
  }

  Future<bool> addLoyaltyCard(LoyaltyCard card) async {
    final res = await _transactionHandler.runTransaction(
      TransactionLoyaltyCardAdd(household: household, card: card),
    );
    await refresh();

    return res;
  }

  Future<bool> updateLoyaltyCard(LoyaltyCard card) async {
    final res = await _transactionHandler.runTransaction(
      TransactionLoyaltyCardUpdate(card: card),
    );
    await refresh();

    return res;
  }

  Future<bool> deleteLoyaltyCard(LoyaltyCard card) async {
    final res = await _transactionHandler.runTransaction(
      TransactionLoyaltyCardRemove(card: card),
    );
    await refresh();

    return res;
  }

  /// Delegates the search to the server (ILIKE over store_name and
  /// card_number) through the transaction handler.
  Future<void> search(String query) {
    return refresh(query);
  }

  Future<void> refresh([String? query]) {
    final state = this.state;
    if (state is SearchLoyaltyCardsCubitState) {
      query = query ?? state.query;
    }
    if (_refreshThread == null || query != _refreshCurrentQuery) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }

    return _refreshThread!;
  }

  Future<void> _refresh([String? query]) async {
    if (state is ListLoyaltyCardsCubitState &&
        state is! SearchLoyaltyCardsCubitState &&
        (state as ListLoyaltyCardsCubitState).cards.isEmpty) {
      emit(const LoadingLoyaltyCardsCubitState());
    }
    cardList = await _transactionHandler.runTransaction(
      TransactionLoyaltyCardsGet(household: household, query: query),
    );

    final LoyaltyCardsCubitState newState = (query != null && query.isNotEmpty)
        ? SearchLoyaltyCardsCubitState(query: query, cards: cardList)
        : ListLoyaltyCardsCubitState(cards: cardList);
    if (_refreshCurrentQuery == query) {
      emit(newState);
      _refreshThread = null;
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offLoyaltyCardUpdate(onLoyaltyCardUpdate);
    super.close();
  }
}

abstract class LoyaltyCardsCubitState extends Equatable {
  const LoyaltyCardsCubitState();

  List<LoyaltyCard> get cards => const [];

  @override
  List<Object?> get props => const [];
}

class LoadingLoyaltyCardsCubitState extends LoyaltyCardsCubitState {
  const LoadingLoyaltyCardsCubitState();
}

class ListLoyaltyCardsCubitState extends LoyaltyCardsCubitState {
  final List<LoyaltyCard> cards;

  const ListLoyaltyCardsCubitState({this.cards = const []});

  @override
  List<Object?> get props => <Object?>[...cards];
}

class SearchLoyaltyCardsCubitState extends ListLoyaltyCardsCubitState {
  final String query;

  const SearchLoyaltyCardsCubitState({
    required this.query,
    super.cards,
  });

  @override
  List<Object?> get props => super.props + [query];
}
