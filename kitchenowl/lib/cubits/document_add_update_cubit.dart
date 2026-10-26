import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/member.dart';
import 'package:houseowl/services/api/api_service.dart';

/// State for the document editor. It loads the household's members
/// for the owner selector, mirroring the task assignee dropdown.
class DocumentAddUpdateCubit extends Cubit<DocumentAddUpdateState> {
  final Household household;

  DocumentAddUpdateCubit(this.household)
      : super(const DocumentAddUpdateState()) {
    getMembers();
  }

  Future<void> getMembers() async {
    final members = await ApiService.getInstance()
            .getHousehold(household)
            .then((r) => r.household?.member) ??
        const <Member>[];
    emit(state.copyWith(members: members));
  }
}

class DocumentAddUpdateState extends Equatable {
  final List<Member> members;

  const DocumentAddUpdateState({this.members = const []});

  DocumentAddUpdateState copyWith({List<Member>? members}) =>
      DocumentAddUpdateState(members: members ?? this.members);

  @override
  List<Object?> get props => [members];
}
