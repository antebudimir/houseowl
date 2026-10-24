import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:houseowl/gen/l10n/app_localizations.dart';
import 'package:houseowl/models/report.dart';
import 'package:houseowl/pages/settings_user_page.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/api/report.dart';
import 'package:houseowl/widgets/confirmation_dialog.dart';

class ReportsListPage extends StatelessWidget {
  const ReportsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports"),
      ),
      body: FutureBuilder(
        future: ApiService.getInstance().getReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(),
            );

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(AppLocalizations.of(context)!.error),
            );
          }

          return ListView.builder(
            itemBuilder: (context, index) {
              final report = snapshot.data![index];
              return Dismissible(
                key: ValueKey<Report>(report),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.redAccent,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.redAccent,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return (await askForConfirmation(
                    context: context,
                    title: Text(
                      "Delete Report",
                    ),
                    content: Text("#${report.id}"),
                  ));
                },
                onDismissed: (direction) {
                  if (report.id != null)
                    ApiService.getInstance().deleteReport(report.id!);
                },
                child: ListTile(
                  leading: Icon(report.user != null
                      ? Icons.person_rounded
                      : Icons.done_all_rounded),
                  title: Text("#${report.id}: " +
                      (report.user?.username ?? "")),
                  isThreeLine: true,
                  subtitle: report.description != null
                      ? RichText(
                          text: TextSpan(children: [
                            if (report.createdAt != null)
                              TextSpan(
                                text: DateFormat.yMMMd()
                                    .add_Hm()
                                    .format(report.createdAt!),
                                style: TextTheme.of(context).bodySmall,
                              ),
                            if (report.createdBy != null)
                              TextSpan(
                                text:
                                    "\nCreated by ${report.createdBy?.username}",
                              ),
                            if (report.description?.isNotEmpty ?? false)
                              TextSpan(text: "\nReason: ${report.description}"),
                          ]),
                        )
                      : null,
                  onTap: () {
                    if (report.user != null) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SettingsUserPage(
                          user: report.user,
                        ),
                      ));
                    }
                  },
                ),
              );
            },
            itemCount: snapshot.data!.length,
          );
        },
      ),
    );
  }
}
