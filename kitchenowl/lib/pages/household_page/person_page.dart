import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:houseowl/cubits/persons_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/person.dart';

import 'person_add_update_page.dart';

class PersonPage extends StatelessWidget {
  final Person person;

  const PersonPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<PersonsCubit>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(person.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.of(context).push<UpdateEnum>(
                  MaterialPageRoute(
                    builder: (ctx) => BlocProvider.value(
                      value: BlocProvider.of<PersonsCubit>(context),
                      child: PersonAddUpdatePage(person: person),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded),
                onPressed: () async {
                  final confirmed = await askForConfirmation(
                    context: context,
                    title: Text(AppLocalizations.of(context)!.personDelete),
                    content: Text(
                      AppLocalizations.of(context)!
                          .personDeleteConfirmation(person.name),
                    ),
                  );
                  if (!confirmed) return;
                  await cubit.deletePerson(person);
                  if (context.mounted) {
                    Navigator.of(context).pop(UpdateEnum.deleted);
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_rounded),
                  title: Text(person.role ?? ""),
                  subtitle: Text(AppLocalizations.of(context)!.role),
                ),
                if (person.birthday != null)
                  ListTile(
                    leading: const Icon(Icons.cake_rounded),
                    title: Text(
                      DateFormat.yMMMMd().format(person.birthday!.toLocal()),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.birthday +
                          (person.hasBirthdayYear
                              ? ""
                              : " (${AppLocalizations.of(context)!.yearUnknown})"),
                    ),
                  ),
                if ((person.phone ?? "").isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone_rounded),
                    title: Text(person.phone!),
                    subtitle: Text(AppLocalizations.of(context)!.phone),
                  ),
                if ((person.email ?? "").isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.alternate_email_rounded),
                    title: Text(person.email!),
                    subtitle: Text(AppLocalizations.of(context)!.email),
                  ),
                if ((person.giftIdea ?? "").isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.giftIdeaLabel,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(person.giftIdea!),
                      ],
                    ),
                  ),
                if ((person.notes ?? "").isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.notes,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(person.notes!),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
