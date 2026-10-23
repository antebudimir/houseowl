import pytest


def _create_card(client, household_id, **overrides):
    payload = {
        "store_name": "SuperMart",
        "card_number": "4006381333931",
        "barcode_format": "ean13",
        **overrides,
    }
    return client.post(f"/api/household/{household_id}/loyalty_card", json=payload)


def test_get_loyalty_cards_empty(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/loyalty_card",
    )
    assert response.status_code == 200
    assert response.get_json() == []


def test_loyalty_card_crud(user_client_with_household, household_id):
    response = _create_card(
        user_client_with_household,
        household_id,
        notes="member card",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["store_name"] == "SuperMart"
    assert data["card_number"] == "4006381333931"
    assert data["barcode_format"] == "ean13"
    assert data["notes"] == "member card"

    card_id = data["id"]

    # GET one
    response = user_client_with_household.get(f"/api/loyalty_card/{card_id}")
    assert response.status_code == 200
    assert response.get_json()["store_name"] == "SuperMart"

    # Update
    response = user_client_with_household.post(
        f"/api/loyalty_card/{card_id}",
        json={"card_number": "4006381333932", "notes": None},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["card_number"] == "4006381333932"
    assert data["notes"] is None

    # Delete
    response = user_client_with_household.delete(f"/api/loyalty_card/{card_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/loyalty_card/{card_id}")
    assert response.status_code == 404


def test_loyalty_card_search(user_client_with_household, household_id):
    _create_card(user_client_with_household, household_id, store_name="SuperMart")
    _create_card(user_client_with_household, household_id, store_name="Kiosk")

    response = user_client_with_household.get(
        f"/api/household/{household_id}/loyalty_card?search=super",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["store_name"] == "SuperMart"


def test_loyalty_card_rejects_unknown_format(user_client_with_household, household_id):
    response = _create_card(
        user_client_with_household,
        household_id,
        barcode_format="foo13",
    )
    assert response.status_code == 400


def test_loyalty_card_format_whitelist_matches_exports(
    user_client_with_household, household_id
):
    from app.models import BARCODE_FORMATS

    response = user_client_with_household.get("/api/loyalty_card/formats")
    assert response.status_code == 200
    assert set(response.get_json()) == BARCODE_FORMATS


@pytest.mark.parametrize(
    "fmt",
    ["code39", "code93", "code128", "ean13", "ean8", "isbn", "itf",
     "upca", "upce", "codabar", "qr", "aztec", "dataMatrix", "pdf417",
     "rm4scc", "telepen"],
)
def test_loyalty_card_accepts_whitelisted_formats(
    user_client_with_household, household_id, fmt
):
    response = _create_card(
        user_client_with_household,
        household_id,
        store_name=f"Store {fmt}",
        barcode_format=fmt,
    )
    assert response.status_code == 200
    assert response.get_json()["barcode_format"] == fmt


def test_loyalty_card_export_import_roundtrip(
    user_client_with_household, household_id
):
    _create_card(
        user_client_with_household,
        household_id,
        store_name="SuperMart",
        notes="member card",
    )
    _create_card(
        user_client_with_household,
        household_id,
        store_name="Kiosk",
        barcode_format="qr",
        card_number="https://kiosk.example/c/42",
    )

    response = user_client_with_household.get(
        f"/api/household/{household_id}/export/loyalty_cards",
    )
    assert response.status_code == 200
    export = response.get_json()
    assert len(export["loyalty_cards"]) == 2
    by_name = {c["store_name"]: c for c in export["loyalty_cards"]}
    first = by_name["SuperMart"]
    assert first["notes"] == "member card"
    assert first["barcode_format"] == "ean13"
    assert "id" not in first and "household_id" not in first

    # Re-import into the same household is idempotent.
    response = user_client_with_household.post(
        f"/api/household/{household_id}/import",
        json={"loyalty_cards": export["loyalty_cards"]},
    )
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/loyalty_card",
    )
    assert len(response.get_json()) == 2
