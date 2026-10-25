import pytest


def test_get_persons_empty(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/person",
    )
    assert response.status_code == 200
    assert response.get_json() == []


def test_add_and_get_person(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={"name": "Jane the plumber", "role": "plumber", "phone": "+123456"},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "Jane the plumber"
    assert data["role"] == "plumber"
    assert data["phone"] == "+123456"
    assert data["household_id"] == household_id

    response = user_client_with_household.get(
        f"/api/household/{household_id}/person",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["name"] == "Jane the plumber"


def test_add_person_with_birthday_sentinel_year(
    user_client_with_household, household_id
):
    # 631152000000 ms == 1990-01-01 UTC, the sentinel "no year known" value
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={"name": "Kid", "birthday": 631152000000},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["birthday"] == 631152000000


def test_add_person_with_member_user_id(user_client_with_household, household_id):
    response = user_client_with_household.get("/api/user")
    assert response.status_code == 200
    user_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={"name": "Me", "user_id": user_id},
    )
    assert response.status_code == 200
    assert response.get_json()["user_id"] == user_id


def test_add_person_with_unknown_user_id_rejected(
    user_client_with_household, household_id
):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={"name": "Ghost", "user_id": 999999},
    )
    assert response.status_code == 404


def test_add_person_without_name_rejected(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={"role": "plumber"},
    )
    assert response.status_code == 400


def test_update_person(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={"name": "Sitter", "phone": "+111"},
    )
    person_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/person/{person_id}",
        json={"phone": "+222", "email": "sitter@example.com"},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["phone"] == "+222"
    assert data["email"] == "sitter@example.com"
    assert data["name"] == "Sitter"


def test_delete_person(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={"name": "Temporary"},
    )
    person_id = response.get_json()["id"]

    response = user_client_with_household.delete(f"/api/person/{person_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/person",
    )
    assert response.get_json() == []


def test_get_person_unauthorized(client, household_id):
    # client fixtures share one Flask test client whose auth header is set by
    # user_client_with_household, so use a fresh unauthenticated client
    unauthenticated = client.application.test_client()
    response = unauthenticated.get(f"/api/household/{household_id}/person")
    assert response.status_code == 401

def test_add_person_with_explicit_null_fields(user_client_with_household, household_id):
    # The Flutter client sends every optional field, with null for unset ones
    # (Person.toJson). A name-only person must be accepted and listed.
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={
            "name": "Only Name",
            "role": None,
            "phone": None,
            "email": None,
            "notes": None,
            "gift_idea": None,
            "birthday": None,
            "user_id": None,
        },
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "Only Name"
    assert data["birthday"] is None

    response = user_client_with_household.get(
        f"/api/household/{household_id}/person",
    )
    assert response.status_code == 200
    assert "Only Name" in [p["name"] for p in response.get_json()]


def test_update_person_clear_birthday(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/person",
        json={
            "name": "Dated",
            "birthday": 631152000000,
            "role": None,
            "phone": None,
            "email": None,
            "notes": None,
            "gift_idea": None,
            "user_id": None,
        },
    )
    assert response.status_code == 200
    person_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/person/{person_id}",
        json={"name": "Dated", "birthday": None},
    )
    assert response.status_code == 200
    assert response.get_json()["birthday"] is None


def test_get_person_unauthorized(client, household_id):
    # client fixtures share one Flask test client whose auth header is set by
    # user_client_with_household, so use a fresh unauthenticated client
    unauthenticated = client.application.test_client()
    response = unauthenticated.get(f"/api/household/{household_id}/person")
    assert response.status_code == 401
