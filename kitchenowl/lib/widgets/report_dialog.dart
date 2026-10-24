import 'package:material_ui/material_ui.dart';
import 'package:houseowl/gen/l10n/app_localizations.dart';
import 'package:houseowl/models/user.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/api/report.dart';
import 'package:houseowl/widgets/text_dialog.dart';

class ReportDialog extends StatelessWidget {
  final User? user;

  const ReportDialog({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return TextDialog(
      title: AppLocalizations.of(context)!.reportUser,
      doneText: AppLocalizations.of(context)!.send,
      hintText: AppLocalizations.of(context)!.reason,
      onDone: (description) => {
        ApiService.getInstance().addReport(
          description: description,
          user: user,
        )
      },
    );
  }
}
