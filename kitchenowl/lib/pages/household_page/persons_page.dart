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
      subtitle: (person.role ?? "").isNotEmpty
          ? Text(
              person.role!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
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
