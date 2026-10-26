import os
from datetime import datetime, timedelta, timezone

from app import db
from app.models import Document, File, Household, HouseholdMember, User
from app.config import UPLOAD_FOLDER


def _make_household() -> Household:
    return Household(name="testhousehold").save()


def _make_file(name: str) -> File:
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    path = os.path.join(UPLOAD_FOLDER, name)
    with open(path, "w") as f:
        f.write("x")
    return File(filename=name).save()


def test_document_defaults(db_session):
    household = _make_household()
    document = Document(title="Passport", household=household).save()

    assert document.id is not None
    assert document.notes is None
    assert document.expires_at is None
    assert document.file_id is None
    assert document.owner_id is None
    assert document.created_at is not None
    assert document.updated_at is not None

    data = document.obj_to_dict()
    assert data["title"] == "Passport"
    assert data["household_id"] == household.id


def test_document_owner_set_null_on_user_delete(db_session):
    household = _make_household()
    user = User(username="jane", name="Jane").save()
    HouseholdMember(household=household, user=user).save()
    document = Document(title="Contract", household=household, owner=user).save()

    assert document.owner_id == user.id

    db.session.delete(user)
    db.session.commit()
    db.session.expire_all()

    document = Document.find_by_id(document.id)
    assert document is not None
    assert document.owner_id is None


def test_file_gc_skips_files_attached_to_documents(db_session):
    household = _make_household()
    attached = _make_file("attached.pdf")
    _make_file("orphan.pdf")

    document = Document(title="Deed", household=household, file=attached).save()
    db.session.expire_all()

    assert not File.find("attached.pdf").isUnused()
    assert File.find("orphan.pdf").isUnused()

    # Deleting the document releases the file for GC again.
    db.session.delete(document)
    db.session.commit()

    assert File.find("attached.pdf").isUnused()


def test_expiring_query_filters_on_expires_at(db_session):
    household = _make_household()
    soon = Document(
        title="Soon",
        household=household,
        expires_at=datetime.now(timezone.utc) + timedelta(days=10),
    ).save()
    far = Document(
        title="Far",
        household=household,
        expires_at=datetime.now(timezone.utc) + timedelta(days=400),
    ).save()
    no_date = Document(title="Eternal", household=household).save()

    cutoff = datetime.now(timezone.utc) + timedelta(days=30)
    results = (
        Document.query.filter(Document.household_id == household.id)
        .filter(Document.expires_at.isnot(None))
        .filter(Document.expires_at <= cutoff)
        .all()
    )
    assert [d.id for d in results] == [soon.id]
    assert far.id not in [d.id for d in results]
    assert no_date.id not in [d.id for d in results]
