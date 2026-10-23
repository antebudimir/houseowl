from datetime import datetime, timedelta, timezone


def _ms(dt):
    return int(dt.timestamp() * 1000)


def _future(hour):
    """A fixed future date at wall time :00, so tests are stable."""
    return datetime.now(timezone.utc).replace(
        hour=hour, minute=0, second=0, microsecond=0
    ) + timedelta(days=30)


def _create_event(client, household_id, **overrides):
    payload = {
        "name": "test event",
        "start": _ms(_future(10)),
        "end": _ms(_future(11)),
    }
    payload.update(overrides)
    return client.post(f"/api/household/{household_id}/event", json=payload)


def _create_person(client, household_id, name):
    return client.post(
        f"/api/household/{household_id}/person", json={"name": name}
    )


def test_create_event_defaults(user_client_with_household, household_id):
    response = _create_event(user_client_with_household, household_id)
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "test event"
    assert data["all_day"] is False
    assert data["location"] is None
    assert data["attendees"] == []
    assert data["start"] == _ms(_future(10))


def test_end_not_after_start_rejected(user_client_with_household, household_id):
    response = _create_event(
        user_client_with_household,
        household_id,
        start=_ms(_future(11)),
        end=_ms(_future(10)),
    )
    assert response.status_code == 400

    response = _create_event(
        user_client_with_household,
        household_id,
        start=_ms(_future(10)),
        end=_ms(_future(10)),
    )
    assert response.status_code == 400


def test_update_event_fields(user_client_with_household, household_id):
    event_id = _create_event(user_client_with_household, household_id).get_json()["id"]

    response = user_client_with_household.post(
        f"/api/event/{event_id}",
        json={
            "name": "renamed",
            "description": "details",
            "location": "community hall",
            "all_day": True,
            "start": _ms(_future(12)),
            "end": _ms(_future(13)),
        },
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "renamed"
    assert data["description"] == "details"
    assert data["location"] == "community hall"
    assert data["all_day"] is True
    assert data["start"] == _ms(_future(12))


def test_range_filter_is_half_open(user_client_with_household, household_id):
    _create_event(user_client_with_household, household_id, name="A")
    _create_event(
        user_client_with_household,
        household_id,
        name="B",
        start=_ms(_future(12)),
        end=_ms(_future(13)),
    )

    base = f"/api/household/{household_id}/event"
    # Window ending exactly at A's start excludes A (half-open).
    response = user_client_with_household.get(
        f"{base}?from=0&to={_ms(_future(10))}"
    )
    assert response.get_json() == []
    # Window starting exactly at A's end includes B, excludes A.
    response = user_client_with_household.get(
        f"{base}?from={_ms(_future(11))}&to=99999999999999"
    )
    assert [e["name"] for e in response.get_json()] == ["B"]


def test_back_to_back_events_do_not_conflict(
    user_client_with_household, household_id
):
    _create_event(user_client_with_household, household_id, name="first")
    response = _create_event(
        user_client_with_household,
        household_id,
        name="second",
        start=_ms(_future(11)),
        end=_ms(_future(12)),
    )
    assert response.status_code == 200


def test_overlap_conflicts_return_409_with_details(
    user_client_with_household, household_id
):
    mom = _create_person(user_client_with_household, household_id, "Mom").get_json()
    _create_event(
        user_client_with_household, household_id, name="existing",
        attendees=[mom["id"]],
    )
    response = _create_event(
        user_client_with_household, household_id, name="overlapping",
        attendees=[mom["id"]],
    )
    assert response.status_code == 409
    conflicts = response.get_json()
    assert len(conflicts) == 1
    assert conflicts[0]["name"] == "existing"
    assert "attendees" in conflicts[0]


def test_containment_conflicts(user_client_with_household, household_id):
    mom = _create_person(user_client_with_household, household_id, "Mom").get_json()
    _create_event(
        user_client_with_household, household_id, name="long",
        attendees=[mom["id"]],
    )
    response = _create_event(
        user_client_with_household,
        household_id,
        name="inside",
        start=_ms(_future(10) + timedelta(minutes=15)),
        end=_ms(_future(10) + timedelta(minutes=30)),
        attendees=[mom["id"]],
    )
    assert response.status_code == 409


def test_conflicts_are_attendee_scoped(user_client_with_household, household_id):
    mom = _create_person(user_client_with_household, household_id, "Mom").get_json()
    dad = _create_person(user_client_with_household, household_id, "Dad").get_json()

    _create_event(
        user_client_with_household,
        household_id,
        name="mom busy",
        attendees=[mom["id"]],
    )
    # Dad at the same time is fine...
    response = _create_event(
        user_client_with_household,
        household_id,
        name="dad free",
        attendees=[dad["id"]],
    )
    assert response.status_code == 200
    # ...but Mom is double-booked.
    response = _create_event(
        user_client_with_household,
        household_id,
        name="mom again",
        attendees=[mom["id"]],
    )
    assert response.status_code == 409
    assert response.get_json()[0]["name"] == "mom busy"

    # Both attending an overlapping event conflicts on the shared person.
    response = _create_event(
        user_client_with_household,
        household_id,
        name="family",
        attendees=[mom["id"], dad["id"]],
    )
    assert response.status_code == 409


def test_no_attendees_never_conflict(user_client_with_household, household_id):
    _create_event(user_client_with_household, household_id, name="existing")
    response = _create_event(
        user_client_with_household,
        household_id,
        name="unassigned",
        attendees=[],
    )
    assert response.status_code == 200


def test_update_excludes_self_from_conflict_check(
    user_client_with_household, household_id
):
    event_id = _create_event(user_client_with_household, household_id).get_json()["id"]
    response = user_client_with_household.post(
        f"/api/event/{event_id}", json={"name": "renamed only"}
    )
    assert response.status_code == 200


def test_update_onto_conflict_returns_409(user_client_with_household, household_id):
    mom = _create_person(user_client_with_household, household_id, "Mom").get_json()
    first = _create_event(
        user_client_with_household, household_id, attendees=[mom["id"]]
    ).get_json()
    second = _create_event(
        user_client_with_household,
        household_id,
        start=_ms(_future(14)),
        end=_ms(_future(15)),
        attendees=[mom["id"]],
    ).get_json()

    # Move second onto first's slot without touching attendees: the update
    # still conflicts with first, but never with itself.
    response = user_client_with_household.post(
        f"/api/event/{second['id']}",
        json={"start": _ms(_future(10)), "end": _ms(_future(11))},
    )
    assert response.status_code == 409
    assert response.get_json()[0]["id"] == first["id"]


def test_attendee_must_belong_to_household(user_client_with_household, household_id):
    response = _create_event(
        user_client_with_household, household_id, attendees=[99999]
    )
    assert response.status_code == 404


def test_conflicts_endpoint(user_client_with_household, household_id):
    mom = _create_person(user_client_with_household, household_id, "Mom").get_json()
    _create_event(
        user_client_with_household,
        household_id,
        name="busy",
        attendees=[mom["id"]],
    )

    base = f"/api/household/{household_id}/event/conflicts"
    response = user_client_with_household.get(
        f"{base}?start={_ms(_future(10))}&end={_ms(_future(11))}&attendee={mom['id']}"
    )
    assert [c["name"] for c in response.get_json()] == ["busy"]

    response = user_client_with_household.get(
        f"{base}?start={_ms(_future(10))}&end={_ms(_future(11))}"
    )
    assert response.get_json() == []

    response = user_client_with_household.get(f"{base}?start={_ms(_future(10))}")
    assert response.status_code == 400


def test_delete_event_cascades_attendees(user_client_with_household, household_id):
    mom = _create_person(user_client_with_household, household_id, "Mom").get_json()
    event_id = _create_event(
        user_client_with_household, household_id, attendees=[mom["id"]]
    ).get_json()["id"]

    response = user_client_with_household.delete(f"/api/event/{event_id}")
    assert response.status_code == 200

    # Mom is untouched and the slot is free again.
    response = _create_event(
        user_client_with_household,
        household_id,
        attendees=[mom["id"]],
    )
    assert response.status_code == 200


def test_list_sorted_by_start(user_client_with_household, household_id):
    _create_event(
        user_client_with_household,
        household_id,
        name="later",
        start=_ms(_future(12)),
        end=_ms(_future(13)),
    )
    _create_event(user_client_with_household, household_id, name="sooner")

    response = user_client_with_household.get(
        f"/api/household/{household_id}/event"
    )
    assert [e["name"] for e in response.get_json()] == ["sooner", "later"]


def test_cross_household_events_invisible(user_client_with_household, household_id):
    _create_event(user_client_with_household, household_id, name="mine")

    # Second household owned by the same user.
    response = user_client_with_household.get("/api/user")
    user_id = response.get_json()["id"]
    user_client_with_household.post(
        "/api/household", json={"name": "other", "member": [user_id]}
    )
    other_id = [
        h for h in user_client_with_household.get("/api/household").get_json()
        if h["name"] == "other"
    ][0]["id"]

    response = user_client_with_household.get(
        f"/api/household/{other_id}/event"
    )
    assert response.get_json() == []

    # Overlap check against the other household doesn't see "mine".
    response = _create_event(user_client_with_household, other_id)
    assert response.status_code == 200
