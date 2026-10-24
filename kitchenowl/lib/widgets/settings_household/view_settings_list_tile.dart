import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/household_add_update/household_add_update_cubit.dart';
import 'package:houseowl/enums/views_enum.dart';
import 'package:houseowl/kitchenowl.dart';

class ViewSettingsListTile<Cubit extends HouseholdAddUpdateCubit<State>,
    State extends HouseholdAddUpdateState> extends StatelessWidget {
  final ViewsEnum view;
  final bool isActive;
  final bool showHandleIfNotOptional;

  const ViewSettingsListTile({
    super.key,
    required this.view,
    this.isActive = false,
    this.showHandleIfNotOptional = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Cubit, State>(
      builder: (context, state) {
        final activeCount = state.viewOrdering.where(state.isViewActive).length;

        return ListTile(
          title: Text(
            view.toLocalizedString(context),
          ),
          leading: Icon(view.toSelectedIcon(context)),
          contentPadding: EdgeInsets.only(left: 16),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The last active view must stay visible — its switch is
              // disabled so the view switcher can never dead-end.
              KitchenOwlSwitch(
                value: isActive,
                onChanged: (!isActive || activeCount > 1)
                    ? (value) =>
                        BlocProvider.of<Cubit>(context).setView(view, value)
                    : null,
              ),
              const VerticalDivider(
                endIndent: 4,
                indent: 4,
              ),
              if (showHandleIfNotOptional)
                const Padding(
                  padding: EdgeInsets.only(left: 4, right: 16),
                  child: Icon(Icons.drag_handle),
                ),
            ],
          ),
        );
      },
    );
  }
}
