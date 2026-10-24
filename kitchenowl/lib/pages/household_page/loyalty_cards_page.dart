import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/loyalty_cards_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/loyalty_card.dart';

import 'loyalty_card_page.dart';

class LoyaltyCardsPage extends StatelessWidget {
  const LoyaltyCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<LoyaltyCardsCubit>(context);

    return SafeArea(
      child: BlocBuilder<LoyaltyCardsCubit, LoyaltyCardsCubitState>(
        builder: (context, state) {
          final Widget body;
          if (state is LoadingLoyaltyCardsCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.cards.isEmpty) {
            body = Center(
              child: Text(
                state is SearchLoyaltyCardsCubitState
                    ? AppLocalizations.of(context)!.noResults
                    : AppLocalizations.of(context)!.emptyLoyaltyCardList,
                textAlign: TextAlign.center,
              ),
            );
          } else {
            body = ListView(
              children:
                  state.cards.map((c) => _LoyaltyCardTile(card: c)).toList(),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: KitchenowlPersistentSearchAnchor(
                  onSearch: cubit.search,
                  suggestionsBuilder: (context, controller) => state.cards
                      .map((e) => e.storeName)
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

class _LoyaltyCardTile extends StatefulWidget {
  final LoyaltyCard card;

  const _LoyaltyCardTile({required this.card});

  @override
  State<_LoyaltyCardTile> createState() => _LoyaltyCardTileState();
}

class _LoyaltyCardTileState extends State<_LoyaltyCardTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.card.storeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _revealed ? widget.card.cardNumber : widget.card.maskedCardNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: const CircleAvatar(child: Icon(Icons.loyalty_outlined)),
      trailing: IconButton(
        tooltip: AppLocalizations.of(context)!.loyaltyCardReveal,
        icon: Icon(
          _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: () => setState(() => _revealed = !_revealed),
      ),
      onTap: () => Navigator.of(context).push<UpdateEnum>(
        MaterialPageRoute(
          builder: (ctx) => LoyaltyCardPage(card: widget.card),
        ),
      ),
    );
  }
}
