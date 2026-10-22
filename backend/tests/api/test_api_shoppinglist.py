import pytest


def test_get_shopping_lists(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/shoppinglist",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "household_id" in data[0]
    assert data[0]["household_id"] == household_id
    assert "id" in data[0]
    assert "name" in data[0]
    assert "default" in data[0]


def test_get_shopping_lists_single_list_is_default(
    user_client_with_household, household_id
):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/shoppinglist",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["default"] is True


def test_get_shopping_lists_default_flag_only_on_first_list(
    user_client_with_household, household_id, shoppinglist_id
):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/shoppinglist", json={"name": "Second list"}
    )
    assert response.status_code == 200
    response = user_client_with_household.get(
        f"/api/household/{household_id}/shoppinglist",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 2
    flags = sorted(entry["default"] for entry in data)
    assert flags == [False, True]


def test_delete_default_shopping_list_blocked(
    user_client_with_household, shoppinglist_id
):
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id}",
    )
    assert response.status_code == 400


def test_delete_shopping_list_removes_items(
    user_client_with_household, household_id, shoppinglist_id, shoppinglist_id_with_item
):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/shoppinglist", json={"name": "Second list"}
    )
    assert response.status_code == 200
    deletable_id = response.get_json()["id"]

    response = user_client_with_household.delete(
        f"/api/shoppinglist/{deletable_id}",
    )
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/shoppinglist/{deletable_id}/items"
    )
    assert response.status_code == 404
    response = user_client_with_household.get(
        f"/api/household/{household_id}/shoppinglist",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["id"] == shoppinglist_id


def test_add_item_by_name(user_client_with_household, shoppinglist_id, item_name):
    data = {"name": item_name}
    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id}/add-item-by-name", json=data
    )
    assert response.status_code == 200


def test_get_items(user_client_with_household, shoppinglist_id_with_item, item_name):
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "name" in data[0]
    assert data[0]["name"] == item_name


def test_remove_item(user_client_with_household, shoppinglist_id_with_item, item_id):
    data = {"item_id": item_id}
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/item", json=data
    )
    assert response.status_code == 200
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 0
