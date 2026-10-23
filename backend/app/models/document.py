from datetime import datetime
from typing import Self, Optional, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import File, Household, Person
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
    contact_id: Mapped[Optional[int]] = db.Column(
        db.Integer, db.ForeignKey("person.id", ondelete="SET NULL"), nullable=True
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
    contact: Mapped[Optional["Person"]] = cast(
        Mapped[Optional["Person"]],
        db.relationship(
            "Person",
            uselist=False,
        ),
    )

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.id == id).first()


from datetime import datetime  # noqa: E402
