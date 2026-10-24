import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/household.dart';

class HouseholdCubit extends Cubit<HouseholdState> {
  HouseholdCubit(Household household)
      : super(HouseholdState(
          household: household,
        )) {
    refresh();
  }

  Future<void> refresh() async {
    final household = await TransactionHandler.getInstance().runTransaction(
      TransactionHouseholdGet(
        household: state.household,
      ),
    );
    if (household == null) {
      emit(NotFoundHouseholdState(household: state.household));
    } else {
      emit(state.copyWith(household: household));
    }
  }
}

class HouseholdState extends Equatable {
  final Household household;

  const HouseholdState({
    required this.household,
  });

  HouseholdState copyWith({
    Household? household,
  }) =>
      HouseholdState(
        household: household ?? this.household,
      );

  @override
  List<Object?> get props => [household];
}

class NotFoundHouseholdState extends HouseholdState {
  const NotFoundHouseholdState({required super.household});
}
