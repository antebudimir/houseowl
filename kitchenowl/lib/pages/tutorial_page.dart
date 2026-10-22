import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int step = 0;

  static const int lastStep = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 1 / (lastStep + 1),
                        end: (step + 1) / (lastStep + 1),
                      ),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.hi(
                        BlocProvider.of<AuthCubit>(context).getUser()?.name ??
                            ""),
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.start,
                  ),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: step != 1,
                      child: IndexedStack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              Expanded(
                                child: Text(AppLocalizations.of(context)!
                                    .tutorialItemDescription1),
                                flex: 2,
                              ),
                              SearchTextField(
                                controller: TextEditingController.fromValue(
                                    TextEditingValue(text: "300g Tomatoes")),
                                onSearch: (s) => Future.value(),
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) => SizedBox(
                                  width: constraints.maxWidth / 3,
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ShoppingItemWidget(
                                      item: ItemWithDescription(
                                        name: "Tomatoes",
                                        description: "300g",
                                        icon: "tomato",
                                      ),
                                      gridStyle: true,
                                      selected: true,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(flex: 3),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              Expanded(
                                child: Text(AppLocalizations.of(context)!
                                    .tutorialItemDescription2),
                                flex: 2,
                              ),
                              SearchTextField(
                                controller: TextEditingController.fromValue(
                                    TextEditingValue(
                                        text: "Raspberry, Frozen")),
                                onSearch: (s) => Future.value(),
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) => SizedBox(
                                  width: constraints.maxWidth / 3,
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ShoppingItemWidget(
                                      item: ItemWithDescription(
                                        name: "Raspberry",
                                        description: "Frozen",
                                        icon: "raspberry",
                                      ),
                                      gridStyle: true,
                                      selected: true,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(flex: 3),
                            ],
                          )
                        ],
                        index: step,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          if (step == 0)
                            Navigator.of(context).pop();
                          else
                            setState(() {
                              step--;
                            });
                        },
                        child: Text(
                          step == 0
                              ? AppLocalizations.of(context)!.skip
                              : AppLocalizations.of(context)!.back,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          if (step < lastStep)
                            setState(() {
                              step++;
                            });
                          else
                            Navigator.of(context).pop();
                        },
                        child: Text(
                          step < lastStep
                              ? AppLocalizations.of(context)!.next
                              : AppLocalizations.of(context)!.okay,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
