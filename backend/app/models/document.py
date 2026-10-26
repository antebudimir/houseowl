import base64
import os
from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING, Any, Optional, Self, cast

from sqlalchemy.orm import Mapped

from app import db
from app.config import UPLOAD_FOLDER
from app.helpers import DbModelAuthorizeMixin

Model = db.Model
if TYPE_CHECKING:
    from app.models import File, Household, User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Document(Model, DbModelAuthorizeMixin):
    __tablename__ = "document"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    title: Mapped[str] = db.Column(db.String(255), nullable=False)
    notes: Mapped[Optional[str]] = db.Column(db.Text, nullable=True)
    expires_at: Mapped[Optional[datetime]] = db.Column(
        db.DateTime(timezone=True), nullable=True, index=True
    )
    file_id: Mapped[Optional[str]] = db.Column(
        db.String(), db.ForeignKey("file.filename"), nullable=True
    )
    # Owner is a household member (user account), not a directory person.
    owner_id: Mapped[Optional[int]] = db.Column(
        db.Integer, db.ForeignKey("user.id", ondelete="SET NULL"), nullable=True
    )
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship(
            "Household",
            uselist=False,
        ),
    )
    file: Mapped[Optional["File"]] = cast(
        Mapped[Optional["File"]],
        db.relationship(
            "File",
            backref="document",
            uselist=False,
        ),
    )
    owner: Mapped[Optional["User"]] = cast(
        Mapped[Optional["User"]],
        db.relationship(
            "User",
            uselist=False,
        ),
    )

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def all_from_household(cls, household_id: int) -> list[Self]:
        return (
            cls.query.filter(cls.household_id == household_id)
            .order_by(cls.updated_at.desc(), cls.id.desc())
            .all()
        )

    @classmethod
    def search(cls, household_id: int, query: str) -> list[Self]:
        # Server-side ILIKE over title and notes, mirroring Note.search.
        looking_for = f"%{query}%"
        return (
            cls.query.filter(cls.household_id == household_id)
            .filter(
                db.or_(
                    cls.title.ilike(looking_for),
                    cls.notes.ilike(looking_for),
                )
            )
            .order_by(cls.updated_at.desc(), cls.id.desc())
            .all()
        )

    @classmethod
    def find_expiring(cls, household_id: int, days: int) -> list[Self]:
        # No lower bound: already-expired documents are the most actionable
        # entries in the vault (an expired passport still needs attention).
        # Stored datetimes are naive-UTC on SQLite; compare with naive UTC so
        # the query works identically on all backends.
        cutoff = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(
            days=days
        )
        return (
            cls.query.filter(cls.household_id == household_id)
            .filter(cls.expires_at.isnot(None))
            .filter(cls.expires_at <= cutoff)
            .order_by(cls.expires_at.asc())
            .all()
        )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = super().obj_to_dict()
        res["file"] = self.file.obj_to_dict() if self.file else None
        res["owner"] = self.owner.obj_to_dict() if self.owner else None
        return res

    def obj_to_export_dict(self) -> dict[str, Any]:
        # Portable representation: no ids, ISO expiry, owner by name and the
        # file blob inlined as base64 so an export is self-contained.
        res: dict[str, Any] = {
            "title": self.title,
            "notes": self.notes,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "owner": self.owner.name if self.owner else None,
            "file": None,
        }
        if self.file:
            path = os.path.join(UPLOAD_FOLDER, self.file.filename)
            data = None
            if os.path.exists(path):
                with open(path, "rb") as f:
                    data = base64.b64encode(f.read()).decode()
            res["file"] = {"filename": self.file.filename, "data": data}
        return res


from datetime import datetime  # noqa: E402
