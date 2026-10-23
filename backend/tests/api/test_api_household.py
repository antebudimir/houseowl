import pytest


def test_get_all_households_empty(admin_client):
    response = admin_client.get(
        "/api/household",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 0


def test_add_household_admin(admin_client, household_name):
    response = admin_client.get(
        "/api/user",
    )
    assert response.status_code == 200
    data = response.get_json()
    admin_user_id = data["id"]
    data = {"name": household_name, "member": [admin_user_id]}
    response = admin_client.post("/api/household", json=data)
    assert response.status_code == 200


def test_add_household_user(user_client, household_name):
    response = user_client.get(
        "/api/user",
    )
    assert response.status_code == 200
    data = response.get_json()
    user_id = data["id"]
    data = {"name": household_name, "member": [user_id]}
    response = user_client.post("/api/household", json=data)
    assert response.status_code == 200


def test_get_all_households(user_client_with_household, household_name):
    response = user_client_with_household.get(
        "/api/household",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["name"] == household_name


def test_update_household_hidden_views(user_client_with_household):
    response = user_client_with_household.get(
        "/api/household",
    )
    assert response.status_code == 200
    household = response.get_json()[0]

    data = {"hidden_views": ["notes", "tasks"]}
    response = user_client_with_household.post(
        f"/api/household/{household['id']}", json=data
    )
    assert response.status_code == 200
    assert sorted(response.get_json()["hidden_views"]) == ["notes", "tasks"]

    data = {"hidden_views": []}
    response = user_client_with_household.post(
        f"/api/household/{household['id']}", json=data
    )
    assert response.status_code == 200
    assert response.get_json()["hidden_views"] == []


def test_update_household_hidden_views_rejects_hiding_all_views(
    user_client_with_household,
):
    response = user_client_with_household.get(
        "/api/household",
    )
    assert response.status_code == 200
    household = response.get_json()[0]

    data = {
        "hidden_views": [
            "items",
            "planned",
            "persons",
            "birthdays",
            "notes",
            "tasks",
            "events",
        ]
    }
    response = user_client_with_household.post(
        f"/api/household/{household['id']}", json=data
    )
    assert response.status_code == 400

    response = user_client_with_household.get(
        "/api/household",
    )
    assert response.get_json()[0]["hidden_views"] == []
