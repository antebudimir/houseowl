import pytest


def test_get_notes_empty(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/note",
    )
    assert response.status_code == 200
    assert response.get_json() == []


def test_add_and_get_note(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/note",
        json={"title": "Wifi", "body": "password is **hunter2**"},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["title"] == "Wifi"
    assert data["body"] == "password is **hunter2**"
    assert data["tags"] == []

    response = user_client_with_household.get(
        f"/api/household/{household_id}/note",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["title"] == "Wifi"


def test_add_note_with_tags(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/note",
        json={"title": "Wifi", "tags": ["home", "admin"]},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert sorted(t["name"] for t in data["tags"]) == ["admin", "home"]

    # Reusing an existing household tag must not duplicate it.
    response = user_client_with_household.post(
        f"/api/household/{household_id}/note",
        json={"title": "Trash days", "tags": ["home"]},
    )
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/household/{household_id}/tag")
    assert response.status_code == 200
    tag_names = [t["name"] for t in response.get_json()]
    assert tag_names.count("home") == 1


def test_search_notes_ilike(user_client_with_household, household_id):
    user_client_with_household.post(
        f"/api/household/{household_id}/note",
        json={"title": "Wifi password", "body": "see the router sticker"},
    )
    user_client_with_household.post(
        f"/api/household/{household_id}/note",
        json={"title": "Groceries", "body": "milk, eggs"},
    )

    # Matches the title, case-insensitively.
    response = user_client_with_household.get(
        f"/api/household/{household_id}/note?search=WIFI",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["title"] == "Wifi password"

    # Matches the body.
    response = user_client_with_household.get(
        f"/api/household/{household_id}/note?search=eggs",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["title"] == "Groceries"

    # No match yields an empty list.
    response = user_client_with_household.get(
        f"/api/household/{household_id}/note?search=nonexistent",
    )
    assert response.status_code == 200
    assert response.get_json() == []


def test_update_note(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/note",
        json={"title": "Wifi", "body": "old", "tags": ["home", "admin"]},
    )
    note_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/note/{note_id}",
        json={"body": "new body", "tags": ["home"]},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["title"] == "Wifi"
    assert data["body"] == "new body"
    assert [t["name"] for t in data["tags"]] == ["home"]


def test_delete_note(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/note",
        json={"title": "Wifi"},
    )
    note_id = response.get_json()["id"]

    response = user_client_with_household.delete(f"/api/note/{note_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/note",
    )
    assert response.get_json() == []


def test_get_note_unauthorized(client, household_id):
    # client fixtures share one Flask test client whose auth header is set by
    # user_client_with_household, so use a fresh unauthenticated client
    unauthenticated = client.application.test_client()
    response = unauthenticated.get(f"/api/household/{household_id}/note")
    assert response.status_code == 401
