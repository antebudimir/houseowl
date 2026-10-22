from typing import Any, Self, Optional, TYPE_CHECKING, cast
from datetime import date, datetime, timezone
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Person(Model, DbModelAuthorizeMixin):
    __tablename__ = "person"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128), nullable=False)
    role: Mapped[Optional[str]] = db.Column(db.String(128), nullable=True)
    phone: Mapped[Optional[str]] = db.Column(db.String(64), nullable=True)
    email: Mapped[Optional[str]] = db.Column(db.String(255), nullable=True)
    notes: Mapped[Optional[str]] = db.Column(db.String, nullable=True)
    birthday: Mapped[Optional[date]] = db.Column(db.Date, nullable=True)
    user_id: Mapped[Optional[int]] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True
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
    user: Mapped[Optional["User"]] = cast(
        Mapped[Optional["User"]],
        db.relationship(
            "User",
            uselist=False,
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = super().obj_to_dict()
        if self.birthday:
            # Shared JSON provider only handles datetime, not bare date
            # (date.replace() has no tzinfo). Convert date -> epoch ms here at
            # the model boundary instead of touching the shared provider.
            res["birthday"] = int(
                datetime(
                    self.birthday.year,
                    self.birthday.month,
                    self.birthday.day,
                    tzinfo=timezone.utc,
                ).timestamp()
                * 1000
            )
        return res

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        return cls.query.filter(cls.id == id).first()
