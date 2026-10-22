import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/gen/l10n/app_localizations.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/api/report.dart';
import 'package:kitchenowl/widgets/text_dialog.dart';

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
