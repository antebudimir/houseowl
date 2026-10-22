import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class HouseholdAboutCubit extends Cubit<HouseholdAboutState> {
  HouseholdAboutCubit(Household household)
      : super(HouseholdAboutState(household: household)) {
    refresh();
  }

  Future<void> refresh() async {
    final household = await TransactionHandler.getInstance()
        .runTransaction(TransactionHouseholdGet(household: state.household));

    emit(HouseholdAboutState(
      household: household ?? state.household,
    ));
  }
}

class HouseholdAboutState extends Equatable {
  final Household household;

  const HouseholdAboutState({
    required this.household,
  });

  @override
  List<Object?> get props => [household];
}
