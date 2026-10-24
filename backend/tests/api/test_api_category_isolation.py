import pytest


@pytest.fixture
def second_household_id(user_client_with_household, household_id):
    response = user_client_with_household.post(
        "/api/household",
        json={"name": "secondhousehold", "member": []},
    )
    assert response.status_code == 200
    return response.get_json()["id"]


@pytest.fixture
def category_id(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/category", json={"name": "HouseholdA"}
    )
    assert response.status_code == 200
    return response.get_json()["id"]


@pytest.fixture
def second_category_id(user_client_with_household, second_household_id):
    response = user_client_with_household.post(
        f"/api/household/{second_household_id}/category",
        json={"name": "HouseholdB"},
    )
    assert response.status_code == 200
    return response.get_json()["id"]


def test_category_listing_is_household_scoped(
    user_client_with_household,
    household_id,
    second_household_id,
    category_id,
    second_category_id,
):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/category",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert [c["id"] for c in data] == [category_id]

    response = user_client_with_household.get(
        f"/api/household/{second_household_id}/category",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert [c["id"] for c in data] == [second_category_id]


def test_item_with_foreign_category_rejected(
    user_client_with_household, household_id, second_category_id
):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/item",
        json={"name": "testitem", "category": {"id": second_category_id}},
    )
    assert response.status_code == 400


def test_item_update_with_foreign_category_rejected(
    user_client_with_household, household_id, category_id, second_category_id
):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/item",
        json={"name": "testitem", "category": {"id": category_id}},
    )
    assert response.status_code == 200
    item_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/item/{item_id}",
        json={"category": {"id": second_category_id}},
    )
    assert response.status_code == 400

    response = user_client_with_household.get(f"/api/item/{item_id}")
    assert response.status_code == 200
    assert response.get_json()["category"]["id"] == category_id


def test_category_merge_across_households_is_noop(
    user_client_with_household,
    household_id,
    second_household_id,
    category_id,
    second_category_id,
):
    response = user_client_with_household.post(
        f"/api/household/{second_household_id}/item",
        json={"name": "otheritem", "category": {"id": second_category_id}},
    )
    assert response.status_code == 200

    response = user_client_with_household.post(
        f"/api/category/{category_id}",
        json={"merge_category_id": second_category_id},
    )
    assert response.status_code == 200

    # The foreign category and its items must be untouched.
    response = user_client_with_household.get(
        f"/api/category/{second_category_id}",
    )
    assert response.status_code == 200
    assert response.get_json()["name"] == "HouseholdB"

    response = user_client_with_household.get(
        f"/api/household/{second_household_id}/item",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["category"]["id"] == second_category_id


def test_expense_routes_are_not_registered(
    user_client_with_household, household_id
):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/expense",
    )
    assert response.status_code == 404
