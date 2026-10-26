import base64
import os
from datetime import datetime

from app.config import UPLOAD_FOLDER
from app.models import Document, File, Household, HouseholdMember, User


def _import_file(args: dict) -> File | None:
    file_args = args.get("file")
    if not file_args or not file_args.get("data"):
        return None

    filename = file_args["filename"]
    existing = File.find(filename)
    if existing:
        # Reuse an already-present blob instead of overwriting it.
        return existing

    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    with open(os.path.join(UPLOAD_FOLDER, filename), "wb") as f:
        f.write(base64.b64decode(file_args["data"]))
    return File(filename=filename).save()


def _import_owner(household: Household, name: str | None) -> User | None:
    # Owners are only linked, never created: the import must not invent user
    # accounts the exporting household may have intentionally dropped.
    if not name:
        return None
    return (
        User.query.join(HouseholdMember, HouseholdMember.user_id == User.id)
        .filter(HouseholdMember.household_id == household.id, User.name == name)
        .first()
    )


def importDocument(household: Household, args: dict):
    # Skip entries that were already imported (idempotent re-import).
    query = Document.query.filter(
        Document.household_id == household.id, Document.title == args["title"]
    )
    existing = query.all()
    for document in existing:
        if document.file and document.file.filename == (args.get("file") or {}).get(
            "filename"
        ):
            return document

    document = Document()
    document.title = args["title"]
    document.notes = args.get("notes")
    document.household = household
    if args.get("expires_at"):
        document.expires_at = datetime.fromisoformat(args["expires_at"])
    document.file = _import_file(args)
    document.owner = _import_owner(household, args.get("owner"))
    document.save()
    return document