from datetime import datetime, timezone
from typing import Any, Optional, Self, TYPE_CHECKING, cast

from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class PlannedBuy(Model, DbModelAuthorizeMixin):
    __tablename__ = "planned_buy"

    STATUS_VALUES = ("idea", "planned", "ordered", "acquired")
    STATUS_ORDER = {status: i for i, status in enumerate(STATUS_VALUES)}

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    status: Mapped[str] = db.Column(
        db.String(16), default="idea", nullable=False
    )
    priority: Mapped[int] = db.Column(db.Integer, default=0, nullable=False)
    category: Mapped[Optional[str]] = db.Column(db.String(128), nullable=True)
    target_date: Mapped[Optional[datetime]] = db.Column(
        db.DateTime, nullable=True
    )
    actual_price: Mapped[Optional[float]] = db.Column(db.Float(), nullable=True)
    acquired_at: Mapped[Optional[datetime]] = db.Column(
        db.DateTime, nullable=True
    )
    # Assignee is a household member (user account), not a directory person.
    assignee_id: Mapped[Optional[int]] = db.Column(
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
    assignee: Mapped[Optional["User"]] = cast(
        Mapped[Optional["User"]],
        db.relationship(
            "User",
            uselist=False,
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = super().obj_to_dict()
        if self.assignee:
            res["assignee"] = self.assignee.obj_to_dict()
        return res

    def apply_status(self, status: str) -> None:
        """Set status and keep acquired_at in sync (server-stamped, idempotent)."""
        self.status = status
        if status == "acquired":
            if self.acquired_at is None:
                self.acquired_at = datetime.now(timezone.utc)
        else:
            self.acquired_at = None

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def all_from_household(cls, household_id: int) -> list[Self]:
        buys = cls.query.filter(cls.household_id == household_id).all()
        return sorted(
            buys,
            key=lambda b: (
                cls.STATUS_ORDER.get(b.status, len(cls.STATUS_ORDER)),
                b.target_date is None,
                b.target_date or datetime.min,
            ),
        )

    @classmethod
    def all_categories(cls, household_id: int) -> list[str]:
        rows = (
            db.session.query(cls.category)
            .filter(
                cls.household_id == household_id,
                cls.category.isnot(None),
            )
            .distinct()
            .order_by(cls.category)
            .all()
        )
        return [row[0] for row in rows]