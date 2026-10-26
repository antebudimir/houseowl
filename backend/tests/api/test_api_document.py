import os

from app.config import UPLOAD_FOLDER
from app.models import File


def _make_file(name: str) -> File:
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    with open(os.path.join(UPLOAD_FOLDER, name), "wb") as f:
        f.write(b"test")
    return File(filename=name).save()


def _create_document(client, household_id, **overrides):
    payload = {"title": "Passport", **overrides}
    return client.post(f"/api/household/{household_id}/document", json=payload)


def test_get_documents_empty(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/document",
    )
    assert response.status_code == 200
    assert response.get_json() == []


def test_document_crud(user_client_with_household, household_id):
    response = _create_document(
        user_client_with_household,
        household_id,
        title="Passport",
        notes="expires soon",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["title"] == "Passport"
    assert data["notes"] == "expires soon"
    assert data["file"] is None
    assert data["owner"] is None
    assert data["expires_at"] is None

    doc_id = data["id"]

    # GET one
    response = user_client_with_household.get(f"/api/document/{doc_id}")
    assert response.status_code == 200
    assert response.get_json()["title"] == "Passport"

    # Update
    response = user_client_with_household.post(
        f"/api/document/{doc_id}", json={"title": "Passport 2036"}
    )
    assert response.status_code == 200
    assert response.get_json()["title"] == "Passport 2036"

    # Delete
    response = user_client_with_household.delete(f"/api/document/{doc_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/document/{doc_id}")
    assert response.status_code == 404


def test_document_empty_title_rejected(user_client_with_household, household_id):
    response = _create_document(user_client_with_household, household_id, title="   ")
    assert response.status_code == 400


def test_document_search(user_client_with_household, household_id):
    _create_document(
        user_client_with_household, household_id, title="Passport", notes="office"
    )
    _create_document(user_client_with_household, household_id, title="Warranty")

    response = user_client_with_household.get(
        f"/api/household/{household_id}/document?search=pass",
    )
    assert response.status_code == 200
    assert [d["title"] for d in response.get_json()] == ["Passport"]

    # Search also matches notes.
    response = user_client_with_household.get(
        f"/api/household/{household_id}/document?search=OFFICE",
    )
    assert [d["title"] for d in response.get_json()] == ["Passport"]


def test_expiring_within_includes_expired(user_client_with_household, household_id):
    from datetime import datetime, timedelta, timezone

    now_ms = lambda dt: int(dt.timestamp() * 1000)  # noqa: E731
    now = datetime.now(timezone.utc)

    expired = _create_document(
        user_client_with_household,
        household_id,
        title="expired",
        expires_at=now_ms(now - timedelta(days=1)),
    )
    today = _create_document(
        user_client_with_household,
        household_id,
        title="today",
        expires_at=now_ms(now),
    )
    tomorrow = _create_document(
        user_client_with_household,
        household_id,
        title="tomorrow",
        expires_at=now_ms(now + timedelta(days=1)),
    )
    soon = _create_document(
        user_client_with_household,
        household_id,
        title="soon",
        expires_at=now_ms(now + timedelta(days=29)),
    )
    far_future = _create_document(
        user_client_with_household,
        household_id,
        title="far",
        expires_at=now_ms(now + timedelta(days=365)),
    )
    _create_document(user_client_with_household, household_id, title="no_expiry")

    response = user_client_with_household.get(
        f"/api/household/{household_id}/document?expiring_within=30d",
    )
    assert response.status_code == 200
    titles = {d["title"] for d in response.get_json()}
    # No lower bound: already-expired documents are included.
    assert titles == {"expired", "today", "tomorrow", "soon"}

    for resp, expected in (
        (expired, now - timedelta(days=1)),
        (today, now),
        (far_future, now + timedelta(days=365)),
    ):
        body = resp.get_json()
        assert body["expires_at"] == now_ms(expected)

    # 7-day window still contains the expired one.
    response = user_client_with_household.get(
        f"/api/household/{household_id}/document?expiring_within=7d",
    )
    assert {d["title"] for d in response.get_json()} == {"expired", "today", "tomorrow"}

    # Bad format is rejected.
    response = user_client_with_household.get(
        f"/api/household/{household_id}/document?expiring_within=30days",
    )
    assert response.status_code == 400


def test_document_file_attach_and_cascade_delete(
    user_client_with_household, household_id
):
    file = _make_file("doc_attached.pdf")
    response = _create_document(
        user_client_with_household, household_id, title="Deed", file_id=file.filename
    )
    assert response.status_code == 200
    assert response.get_json()["file"]["filename"] == file.filename

    doc_id = response.get_json()["id"]
    response = user_client_with_household.delete(f"/api/document/{doc_id}")
    assert response.status_code == 200

    # The File row and its blob are gone with the document.
    assert File.find(file.filename) is None
    assert not os.path.exists(os.path.join(UPLOAD_FOLDER, file.filename))


def _add_member(client, household_id, admin_username, admin_password, username):
    """Create a fresh user (needs admin auth) and add them to the household."""
    admin = client.application.test_client()
    response = admin.post(
        "/api/auth", json={"username": admin_username, "password": admin_password}
    )
    assert response.status_code == 200
    admin.environ_base["HTTP_AUTHORIZATION"] = (
        f"Bearer {response.get_json()['access_token']}"
    )
    response = admin.post(
        "/api/user/new",
        json={"username": username, "name": username, "password": "memberpwd"},
    )
    assert response.status_code == 200

    # /user/new returns no id; log the member in to read it.
    response = admin.post(
        "/api/auth", json={"username": username, "password": "memberpwd"}
    )
    assert response.status_code == 200
    admin.environ_base["HTTP_AUTHORIZATION"] = (
        f"Bearer {response.get_json()['access_token']}"
    )
    user = admin.get("/api/user").get_json()

    response = client.put(
        f"/api/household/{household_id}/member/{user['id']}", json={}
    )
    assert response.status_code == 200
    return user


def test_document_owner_clearable(user_client_with_household, household_id,
                                   admin_username, admin_password):
    member = _add_member(
        user_client_with_household, household_id, admin_username, admin_password,
        "docowner1",
    )

    response = _create_document(
        user_client_with_household, household_id, title="Deed",
        owner_id=member["id"],
    )
    assert response.status_code == 200
    doc_id = response.get_json()["id"]
    assert response.get_json()["owner"]["id"] == member["id"]

    response = user_client_with_household.post(
        f"/api/document/{doc_id}", json={"owner_id": None}
    )
    assert response.status_code == 200

    response = user_client_with_household.get(f"/api/document/{doc_id}")
    assert response.status_code == 200
    assert response.get_json()["owner"] is None


def test_document_invalid_owner_rejected(user_client_with_household, household_id):
    response = _create_document(
        user_client_with_household, household_id, title="Deed", owner_id=999999
    )
    assert response.status_code == 400


def test_document_export_import_roundtrip(
    user_client_with_household, household_id, admin_username, admin_password
):
    import base64
    import os

    file = _make_file("export_me.pdf")
    member = _add_member(
        user_client_with_household, household_id, admin_username, admin_password,
        "docowner2",
    )
    person_name = member["name"]

    from datetime import datetime, timedelta, timezone

    expiry = datetime.now(timezone.utc) + timedelta(days=30)
    _create_document(
        user_client_with_household,
        household_id,
        title="Passport",
        notes="vault",
        expires_at=int(expiry.timestamp() * 1000),
        owner_id=member["id"],
        file_id=file.filename,
    )

    # Export
    response = user_client_with_household.get(
        f"/api/household/{household_id}/export/documents"
    )
    assert response.status_code == 200
    docs = response.get_json()["documents"]
    assert len(docs) == 1
    exported = docs[0]
    assert exported["title"] == "Passport"
    assert exported["notes"] == "vault"
    assert exported["owner"] == person_name
    assert exported["expires_at"] is not None
    assert exported["file"]["filename"] == file.filename
    with open(os.path.join(UPLOAD_FOLDER, file.filename), "rb") as f:
        assert base64.b64decode(exported["file"]["data"]) == f.read()

    # Import into the same household is idempotent (deduped).
    response = user_client_with_household.post(
        f"/api/household/{household_id}/import", json={"documents": docs}
    )
    assert response.status_code == 200
    response = user_client_with_household.get(
        f"/api/household/{household_id}/document"
    )
    assert len(response.get_json()) == 1


def test_document_import_recreates_file_and_links_owner(
    user_client_with_household, household_id
):
    import base64
    import os
    from datetime import datetime, timezone

    expiry = datetime(2030, 1, 2, 3, 4, 5, tzinfo=timezone.utc)
    payload = {
        "documents": [
            {
                "title": "Deed",
                "notes": None,
                "expires_at": expiry.isoformat(),
                "owner": None,
                "file": {
                    "filename": "imported_deed.pdf",
                    "data": base64.b64encode(b"blob").decode(),
                },
            }
        ]
    }
    response = user_client_with_household.post(
        f"/api/household/{household_id}/import", json=payload
    )
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/document"
    )
    docs = response.get_json()
    assert len(docs) == 1
    assert docs[0]["title"] == "Deed"
    assert docs[0]["file"]["filename"] == "imported_deed.pdf"
    assert File.find("imported_deed.pdf") is not None
    with open(os.path.join(UPLOAD_FOLDER, "imported_deed.pdf"), "rb") as f:
        assert f.read() == b"blob"
    # ISO export round-trips through epoch-ms on the API.
    assert docs[0]["expires_at"] == int(expiry.timestamp() * 1000)


def test_document_import_links_existing_owner_by_name(
    user_client_with_household, household_id, admin_username, admin_password
):
    member = _add_member(
        user_client_with_household, household_id, admin_username, admin_password,
        "Bob",
    )
    user_id = member["id"]

    payload = {
        "documents": [
            {"title": "Contract", "owner": "Bob", "file": None},
        ]
    }
    response = user_client_with_household.post(
        f"/api/household/{household_id}/import", json=payload
    )
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/document"
    )
    assert response.get_json()[0]["owner"]["id"] == user_id


def test_document_non_member_forbidden(
    client, user_client_with_household, household_id, admin_username, admin_password
):
    response = _create_document(user_client_with_household, household_id, title="Deed")
    doc_id = response.get_json()["id"]

    # A regular user who is not a member of this household; user creation
    # needs a server-admin session, so (re-)authenticate the admin first.
    admin = client.application.test_client()
    response = admin.post(
        "/api/auth", json={"username": admin_username, "password": admin_password}
    )
    assert response.status_code == 200
    admin.environ_base["HTTP_AUTHORIZATION"] = (
        f"Bearer {response.get_json()['access_token']}"
    )

    other = client.application.test_client()
    response = admin.post(
        "/api/user/new",
        json={"username": "otheruser", "name": "other", "password": "otherpwd"},
    )
    assert response.status_code == 200
    response = other.post(
        "/api/auth", json={"username": "otheruser", "password": "otherpwd"}
    )
    assert response.status_code == 200
    other.environ_base["HTTP_AUTHORIZATION"] = (
        f"Bearer {response.get_json()['access_token']}"
    )

    response = other.get(f"/api/household/{household_id}/document")
    assert response.status_code == 403
    response = other.post(
        f"/api/household/{household_id}/document", json={"title": "x"}
    )
    assert response.status_code == 403
    response = other.get(f"/api/document/{doc_id}")
    assert response.status_code == 403
    response = other.delete(f"/api/document/{doc_id}")
    assert response.status_code == 403
