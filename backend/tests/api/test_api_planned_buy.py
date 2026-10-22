def test_create_planned_buy_defaults(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/planned_buy",
        json={"name": "New shelf"},
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "New shelf"
    assert data["status"] == "idea"
    assert data["priority"] == 0
    assert data["acquired_at"] is None

    response = user_client_with_household.get(
        f"/api/planned_buy/{data['id']}",
    )
    assert response.status_code == 200
    assert response.get_json()["name"] == "New shelf"


def test_list_sorted_by_status_then_target_date(
    user_client_with_household, household_id
):
    base = f"/api/household/{household_id}/planned_buy"
    buys = [
        {"name": "acquired item", "status": "acquired"},
        {"name": "planned item", "status": "planned"},
        {"name": "idea later", "target_date": 1893456000000},
        {"name": "idea sooner", "target_date": 1893369600000},
        {"name": "idea no date"},
    ]
    for buy in buys:
        response = user_client_with_household.post(base, json=buy)
        assert response.status_code == 200

    response = user_client_with_household.get(base)
    assert response.status_code == 200
    names = [b["name"] for b in response.get_json()]
    assert names == [
        "idea sooner",
        "idea later",
        "idea no date",
        "planned item",
        "acquired item",
    ]


def test_list_filter_status_and_assignee_me(
    user_client_with_household, household_id
):
    base = f"/api/household/{household_id}/planned_buy"
    response = user_client_with_household.get(f"/api/household/{household_id}/person")
    assert response.status_code == 200
    persons = response.get_json()

    response = user_client_with_household.post(
        base, json={"name": "assigned", "status": "ordered"}
    )
    assert response.status_code == 200
    buy_id = response.get_json()["id"]
    if persons:
        response = user_client_with_household.post(
            f"/api/planned_buy/{buy_id}",
            json={"assignee_id": persons[0]["id"]},
        )
        assert response.status_code == 200

    user_client_with_household.post(base, json={"name": "unassigned"})

    response = user_client_with_household.get(f"{base}?status=ordered")
    data = response.get_json()
    assert [b["name"] for b in data] == ["assigned"]

    response = user_client_with_household.get(f"{base}?assignee=me")
    data = response.get_json()
    if persons:
        assert [b["name"] for b in data] == ["assigned"]
    else:
        assert data == []

def test_acquired_at_stamped_and_cleared(user_client_with_household, household_id):
    base = f"/api/household/{household_id}/planned_buy"
    response = user_client_with_household.post(
        base, json={"name": "drill", "status": "acquired"}
    )
    data = response.get_json()
    assert data["status"] == "acquired"
    assert data["acquired_at"] is not None
    acquired_at = data["acquired_at"]

    # transitioning again stays idempotent
    response = user_client_with_household.post(
        f"/api/planned_buy/{data['id']}", json={"status": "acquired"}
    )
    assert response.get_json()["acquired_at"] == acquired_at

    response = user_client_with_household.post(
        f"/api/planned_buy/{data['id']}", json={"status": "ordered"}
    )
    assert response.get_json()["acquired_at"] is None


def test_update_planned_buy_fields(user_client_with_household, household_id):
    base = f"/api/household/{household_id}/planned_buy"
    response = user_client_with_household.post(base, json={"name": "lamp"})
    buy_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/planned_buy/{buy_id}",
        json={
            "name": "floor lamp",
            "status": "planned",
            "priority": 2,
            "category": "Living room",
            "target_date": 1893369600000,
            "actual_price": 49.99,
        },
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "floor lamp"
    assert data["status"] == "planned"
    assert data["priority"] == 2
    assert data["category"] == "Living room"
    assert data["target_date"] is not None
    assert data["actual_price"] == 49.99

    # clearing nullable fields
    response = user_client_with_household.post(
        f"/api/planned_buy/{buy_id}",
        json={"category": None, "target_date": None, "assignee_id": None},
    )
    data = response.get_json()
    assert data["category"] is None
    assert data["target_date"] is None
    assert data["assignee_id"] is None


def test_invalid_status_rejected(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/planned_buy",
        json={"name": "bad", "status": "bought"},
    )
    assert response.status_code == 400


def test_categories_distinct(user_client_with_household, household_id):
    base = f"/api/household/{household_id}/planned_buy"
    user_client_with_household.post(base, json={"name": "a", "category": "Garden"})
    user_client_with_household.post(base, json={"name": "b", "category": "Garden"})
    user_client_with_household.post(base, json={"name": "c", "category": "Tools"})
    user_client_with_household.post(base, json={"name": "d"})

    response = user_client_with_household.get(f"{base}/categories")
    assert response.status_code == 200
    assert response.get_json() == ["Garden", "Tools"]


def test_delete_planned_buy(user_client_with_household, household_id):
    base = f"/api/household/{household_id}/planned_buy"
    response = user_client_with_household.post(base, json={"name": "temp"})
    buy_id = response.get_json()["id"]

    response = user_client_with_household.delete(f"/api/planned_buy/{buy_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/planned_buy/{buy_id}")
    assert response.status_code == 404


def test_planned_buy_requires_auth(client):
    response = client.get("/api/planned_buy/1")
    assert response.status_code == 401
