import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

/// Tag state for the note editor. Mirrors the recipe editor: it loads the
/// household's tag vocabulary and tracks the selection for the shared
/// [KitchenOwlTagSelector].
class NoteAddUpdateCubit extends Cubit<NoteAddUpdateState> {
  final Household household;

  NoteAddUpdateCubit(this.household, {Set<Tag> selectedTags = const {}})
      : super(NoteAddUpdateState(selectedTags: selectedTags)) {
    getTags();
  }

  Future<void> getTags() async {
    final tags = await TransactionHandler.getInstance()
        .runTransaction(TransactionTagGetAll(household: household));
    emit(state.copyWith(tags: tags));
  }

  void selectTag(Tag tag, bool selected) {
    final tags = Set<Tag>.from(state.selectedTags);
    selected ? tags.add(tag) : tags.remove(tag);
    emit(state.copyWith(selectedTags: tags));
  }

  void addTag(String name) {
    final tag = Tag(name: name);
    final newTags = Set<Tag>.from(state.tags)..add(tag);
    emit(state.copyWith(
      tags: newTags,
      selectedTags: Set<Tag>.from(state.selectedTags)..add(tag),
    ));
  }
}

class NoteAddUpdateState extends Equatable {
  final Set<Tag> tags;
  final Set<Tag> selectedTags;

  const NoteAddUpdateState({
    this.tags = const {},
    this.selectedTags = const {},
  });

  NoteAddUpdateState copyWith({
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
  }) =>
      NoteAddUpdateState(
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
      );

  @override
  List<Object?> get props => [tags, selectedTags];
}
