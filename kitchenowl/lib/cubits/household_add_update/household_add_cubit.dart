import 'package:houseowl/enums/views_enum.dart';
import 'package:houseowl/helpers/named_bytearray.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/member.dart';
import 'package:houseowl/models/nullable.dart';
import 'package:houseowl/models/user.dart';
import 'package:houseowl/services/api/api_service.dart';

import 'household_add_update_cubit.dart';

class HouseholdAddCubit extends HouseholdAddUpdateCubit<HouseholdAddState> {
  HouseholdAddCubit(String? locale, User user)
      : super(HouseholdAddState(
          members: [Member.fromUser(user, admin: true)],
        )) {
    ApiService.getInstance()
        .getSupportedLanguages()
        .then((value) => emit(state.copyWith(
              supportedLanguages: value,
              language: Nullable(state.language ??
                  ((value?.containsKey(locale) ?? false) ? locale : null)),
            )));
  }

  @override
  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  @override
  void setImage(NamedByteArray image) {
    emit(state.copyWith(image: image));
  }

  @override
  void setView(ViewsEnum view, bool value) {
    final l = List.of(state.hiddenViews);
    if (value) {
      l.remove(view);
    } else {
      // Never hide the last active view — the view switcher would dead-end.
      if (state.viewOrdering.where(state.isViewActive).length <= 1) {
        return;
      }
      l.add(view);
    }
    emit(state.copyWith(hiddenViews: l));
  }

  @override
  void reorderView(int oldIndex, int newIndex) {
    final l = List.of(state.viewOrdering);
    l.insert(newIndex, l.removeAt(oldIndex));
    emit(state.copyWith(viewOrdering: l));
  }

  @override
  void resetViewOrder() {
    emit(state.copyWith(viewOrdering: ViewsEnum.values));
  }

  void removeMember(Member member) {
    if (member.hasAdminRights()) return;
    final l = List.of(state.members);
    emit(state.copyWith(
      members: l..removeWhere((m) => m.id == member.id),
    ));
  }

  void addMember(Member member) {
    final l = List.of(state.members);
    emit(state.copyWith(
      members: l..add(member),
    ));
  }

  Future<Household?> create() async {
    final _state = state;
    if (!_state.isValid()) return null;
    String? image;
    if (_state.image != null) {
      image = _state.image!.isEmpty
          ? ''
          : await ApiService.getInstance().uploadBytes(_state.image!);
    }

    return ApiService.getInstance().addHousehold(Household(
      id: 0,
      name: _state.name,
      image: image,
      language: _state.language,
      viewOrdering: _state.viewOrdering,
      hiddenViews: _state.hiddenViews,
      member: _state.members,
    ));
  }

  @override
  Future<void> setLanguage(String? langCode) {
    emit(state.copyWith(language: Nullable(langCode)));

    return Future.value();
  }
}

class HouseholdAddState extends HouseholdAddUpdateState {
  final NamedByteArray? image;
  final List<Member> members;

  const HouseholdAddState({
    super.name = "",
    this.image,
    super.language,
    super.viewOrdering = ViewsEnum.values,
    super.hiddenViews = const [],
    super.supportedLanguages,
    this.members = const [],
  });

  HouseholdAddState copyWith({
    String? name,
    NamedByteArray? image,
    Nullable<String>? language,
    List<ViewsEnum>? viewOrdering,
    List<ViewsEnum>? hiddenViews,
    Map<String, String>? supportedLanguages,
    List<Member>? members,
  }) =>
      HouseholdAddState(
        name: name ?? this.name,
        image: image ?? this.image,
        language: (language ?? Nullable(this.language)).value,
        viewOrdering: viewOrdering ?? this.viewOrdering,
        hiddenViews: hiddenViews ?? this.hiddenViews,
        supportedLanguages: supportedLanguages ?? this.supportedLanguages,
        members: members ?? this.members,
      );

  @override
  List<Object?> get props => super.props + [image, members];

  bool isValid() => name.replaceAll(" ", "").isNotEmpty;
}
