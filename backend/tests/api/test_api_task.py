from datetime import date, timedelta


def _create_task(client, household_id, **overrides):
    payload = {"name": "test task"}
    payload.update(overrides)
    return client.post(f"/api/household/{household_id}/task", json=payload)


def test_create_task_defaults(user_client_with_household, household_id):
    response = _create_task(user_client_with_household, household_id)
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "test task"
    assert data["status"] == "open"
    assert data["priority"] == 0
    assert data["recurrence"] == "none"
    assert data["due_date"] is None
    assert data["completed_at"] is None
    assert data["tags"] == []


def test_list_sorted_open_first_due_nulls_last(user_client_with_household, household_id):
    base = f"/api/household/{household_id}/task"
    _create_task(
        user_client_with_household, household_id,
        name="no date", priority=2,
    )
    _create_task(
        user_client_with_household, household_id,
        name="later", due_date=str(date.today() + timedelta(days=5)),
    )
    _create_task(
        user_client_with_household, household_id,
        name="sooner", due_date=str(date.today() + timedelta(days=1)),
    )
    done = _create_task(
        user_client_with_household, household_id, name="already done"
    )
    user_client_with_household.post(
        f"/api/task/{done.get_json()['id']}", json={"status": "done"}
    )

    response = user_client_with_household.get(base)
    assert response.status_code == 200
    names = [t["name"] for t in response.get_json()]
    assert names == ["sooner", "later", "no date", "already done"]


def test_list_filter_status_tag(user_client_with_household, household_id):
    base = f"/api/household/{household_id}/task"
    _create_task(
        user_client_with_household, household_id, name="tagged", tags=["fix"]
    )
    _create_task(user_client_with_household, household_id, name="plain")

    response = user_client_with_household.get(f"{base}?tag=fix")
    assert [t["name"] for t in response.get_json()] == ["tagged"]

    response = user_client_with_household.get(f"{base}?status=all")
    assert len(response.get_json()) == 2


def test_update_task_fields(user_client_with_household, household_id):
    response = _create_task(user_client_with_household, household_id)
    task_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/task/{task_id}",
        json={
            "name": "renamed",
            "description": "details",
            "priority": 3,
            "recurrence": "weekly",
            "due_date": "2026-11-01",
            "tags": ["clean"],
        },
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "renamed"
    assert data["description"] == "details"
    assert data["priority"] == 3
    assert data["recurrence"] == "weekly"
    assert data["due_date"] == "2026-11-01"
    assert [t["name"] for t in data["tags"]] == ["clean"]


def test_invalid_recurrence_and_due_date_rejected(
    user_client_with_household, household_id
):
    response = _create_task(
        user_client_with_household, household_id, recurrence="hourly"
    )
    assert response.status_code == 400

    response = _create_task(
        user_client_with_household, household_id, due_date="not-a-date"
    )
    assert response.status_code == 400


def test_delete_task(user_client_with_household, household_id):
    response = _create_task(user_client_with_household, household_id)
    task_id = response.get_json()["id"]

    response = user_client_with_household.delete(f"/api/task/{task_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/task/{task_id}")
    assert response.status_code == 404


def test_task_requires_auth(client):
    response = client.get("/api/task/1")
    assert response.status_code == 401


def test_assignee_and_buy_validation(user_client_with_household, household_id):
    response = _create_task(
        user_client_with_household, household_id, assignee_id=99999
    )
    assert response.status_code == 404

    response = _create_task(user_client_with_household, household_id, buy_id=99999)
    assert response.status_code == 404


def test_buy_deleted_sets_task_buy_null(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/planned_buy", json={"name": "paint"}
    )
    buy_id = response.get_json()["id"]

    response = _create_task(
        user_client_with_household, household_id, name="prep", buy_id=buy_id
    )
    assert response.get_json()["buy"]["id"] == buy_id
    task_id = response.get_json()["id"]

    response = user_client_with_household.delete(f"/api/planned_buy/{buy_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/task/{task_id}")
    assert response.status_code == 200
    assert response.get_json()["buy"] is None


def test_complete_non_recurring_no_clone(user_client_with_household, household_id):
    response = _create_task(user_client_with_household, household_id)
    task_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/task/{task_id}", json={"status": "done"}
    )
    assert response.status_code == 200
    assert response.get_json()["completed_at"] is not None

    response = user_client_with_household.get(
        f"/api/household/{household_id}/task?status=all"
    )
    assert len(response.get_json()) == 1


def test_complete_daily_overdue_catches_up(user_client_with_household, household_id):
    # Due three days ago: the successor is rescheduled to tomorrow, not
    # three clones are generated.
    overdue = str(date.today() - timedelta(days=3))
    response = _create_task(
        user_client_with_household, household_id,
        name="bins", recurrence="daily", due_date=overdue,
    )
    task_id = response.get_json()["id"]

    user_client_with_household.post(f"/api/task/{task_id}", json={"status": "done"})

    response = user_client_with_household.get(
        f"/api/household/{household_id}/task?status=open"
    )
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["due_date"] == str(date.today() + timedelta(days=1))
    assert data[0]["name"] == "bins"


def test_complete_monthly_clamps_day(user_client_with_household, household_id):
    # Jan 31 monthly, caught up to the present: day-clamped months in
    # between prove the calendar-safe arithmetic.
    response = _create_task(
        user_client_with_household, household_id,
        name="rent", recurrence="monthly", due_date="2026-01-31",
    )
    task_id = response.get_json()["id"]

    user_client_with_household.post(f"/api/task/{task_id}", json={"status": "done"})

    response = user_client_with_household.get(
        f"/api/household/{household_id}/task?status=open"
    )
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["due_date"] == "2026-10-31"


def test_complete_is_idempotent(user_client_with_household, household_id):
    response = _create_task(
        user_client_with_household, household_id, recurrence="daily"
    )
    task_id = response.get_json()["id"]

    user_client_with_household.post(f"/api/task/{task_id}", json={"status": "done"})
    user_client_with_household.post(f"/api/task/{task_id}", json={"status": "done"})

    response = user_client_with_household.get(
        f"/api/household/{household_id}/task?status=all"
    )
    assert len(response.get_json()) == 2  # original + exactly one successor

    # Reopening clears the stamp; re-completing then clones exactly once.
    user_client_with_household.post(f"/api/task/{task_id}", json={"status": "open"})
    response = user_client_with_household.get(f"/api/task/{task_id}")
    assert response.get_json()["completed_at"] is None
    user_client_with_household.post(f"/api/task/{task_id}", json={"status": "done"})
    response = user_client_with_household.get(
        f"/api/household/{household_id}/task?status=all"
    )
    assert len(response.get_json()) == 3


def test_successor_copies_tags(user_client_with_household, household_id):
    response = _create_task(
        user_client_with_household, household_id,
        name="gutters", recurrence="yearly", tags=["clean", "fix"],
    )
    task_id = response.get_json()["id"]

    user_client_with_household.post(f"/api/task/{task_id}", json={"status": "done"})

    response = user_client_with_household.get(
        f"/api/household/{household_id}/task?status=open"
    )
    tags = sorted(t["name"] for t in response.get_json()[0]["tags"])
    assert tags == ["clean", "fix"]


def test_tag_merge_repoints_tasks(user_client_with_household, household_id):
    base = f"/api/household/{household_id}/tag"
    response = user_client_with_household.post(base, json={"name": "alpha"})
    keep_id = response.get_json()["id"]
    response = user_client_with_household.post(base, json={"name": "beta"})
    merge_id = response.get_json()["id"]

    response = _create_task(
        user_client_with_household, household_id, name="tagged", tags=["beta"]
    )
    task_id = response.get_json()["id"]

    response = user_client_with_household.post(
        f"/api/tag/{keep_id}", json={"merge_tag_id": merge_id}
    )
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/task/{task_id}")
    tags = [t["name"] for t in response.get_json()["tags"]]
    assert tags == ["alpha"]
