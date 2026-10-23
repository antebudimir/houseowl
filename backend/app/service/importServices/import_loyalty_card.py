from app.models import Household, LoyaltyCard


def importLoyaltyCard(household: Household, args: dict):
    # Skip entries that were already imported (idempotent re-import).
    existing = LoyaltyCard.query.filter(
        LoyaltyCard.household_id == household.id,
        LoyaltyCard.store_name == args["store_name"],
        LoyaltyCard.card_number == args["card_number"],
    ).first()
    if existing:
        return existing

    card = LoyaltyCard()
    card.store_name = args["store_name"]
    card.card_number = args["card_number"]
    card.barcode_format = args["barcode_format"]
    card.notes = args.get("notes")
    card.household = household
    card.save()
    return card