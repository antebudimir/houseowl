import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/persons_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/person.dart';

import 'person_page.dart';

class PersonsPage extends StatelessWidget {
  const PersonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<PersonsCubit>(context);

    return SafeArea(
      child: BlocBuilder<PersonsCubit, PersonsCubitState>(
        builder: (context, state) {
          final Widget body;
          if (state is LoadingPersonsCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.persons.isEmpty) {
            body = Center(
              child: Text(
                AppLocalizations.of(context)!.emptyPersonList,
                textAlign: TextAlign.center,
              ),
            );
          } else {
            body = ListView.builder(
              itemCount: state.persons.length,
              itemBuilder: (context, i) =>
                  _PersonTile(person: state.persons[i]),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: KitchenowlPersistentSearchAnchor(
                  onSearch: cubit.search,
                  suggestionsBuilder: (context, controller) => state.persons
                      .map((e) => e.name)
                      .where((e) => e
                          .toLowerCase()
                          .startsWith(controller.text.toLowerCase()))
                      .toSet()
                      .toList(),
                ),
              ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  /// Secondary metadata line: role/label first, then phone and email, using
  /// only what the person actually has.
  String? _contactLine(Person person) {
    final parts = <String>[
      if ((person.role ?? "").isNotEmpty) person.role!,
      if ((person.phone ?? "").isNotEmpty) person.phone!,
      if ((person.email ?? "").isNotEmpty) person.email!,
    ];

    return parts.isEmpty ? null : parts.join(" · ");
  }


  final Person person;

  const _PersonTile({required this.person});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        person.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _contactLine(person) == null
          ? null
          : Text(
              _contactLine(person)!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      leading: CircleAvatar(
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : "?",
        ),
      ),
      onTap: () => Navigator.of(context).push<UpdateEnum>(
        MaterialPageRoute(
          builder: (ctx) => PersonPage(person: person),
        ),
      ),
    );
  }
}
