from typing import Any, List, Optional, Self, TYPE_CHECKING, cast

from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, Person
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Event(Model, DbModelAuthorizeMixin):
    __tablename__ = "event"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128), nullable=False)
    description: Mapped[Optional[str]] = db.Column(db.Text, nullable=True)
    location: Mapped[Optional[str]] = db.Column(db.String(256), nullable=True)
    # UTC instants. The shared JSON provider serializes datetime -> epoch ms;
    # the client renders in local time and sends epoch ms back, so the server
    # never does local-time math. Intervals are half-open [start, end).
    start: Mapped[Any] = db.Column(db.DateTime, nullable=False)
    end: Mapped[Any] = db.Column(db.DateTime, nullable=False)
    # Client-side rendering flag: an all-day event is stored as the UTC
    # instants of the creator's local [midnight, next midnight).
    all_day: Mapped[bool] = db.Column(
        db.Boolean, default=False, nullable=False
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
    attendees: Mapped[List["EventAttendee"]] = cast(
        Mapped[List["EventAttendee"]],
        db.relationship(
            "EventAttendee",
            back_populates="event",
            cascade="all, delete-orphan",
            lazy="joined",
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = super().obj_to_dict()
        res["attendees"] = [
            con.person.obj_to_dict() for con in self.attendees
        ]
        return res

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def all_from_household(cls, household_id: int) -> list[Self]:
        return (
            cls.query.filter(cls.household_id == household_id)
            .order_by(cls.start, cls.id)
            .all()
        )

    @classmethod
    def find_conflicts(
        cls,
        household_id: int,
        start,
        end,
        attendee_ids: List[int],
        exclude_id: Optional[int] = None,
    ) -> list[Self]:
        """Events overlapping [start, end) (half-open) sharing an attendee.

        Back-to-back events (end == next start) do not conflict. With no
        attendees the check cannot double-book anyone and finds nothing.
        """
        if not attendee_ids or not start or not end or end <= start:
            return []
        query = cls.query.filter(
            cls.household_id == household_id,
            cls.start < end,
            cls.end > start,
            cls.attendees.any(EventAttendee.person_id.in_(attendee_ids)),
        )
        if exclude_id is not None:
            query = query.filter(cls.id != exclude_id)
        return query.order_by(cls.start).all()


class EventAttendee(Model):
    __tablename__ = "event_attendee"

    event_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("event.id", ondelete="CASCADE"), primary_key=True
    )
    person_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("person.id", ondelete="CASCADE"), primary_key=True
    )

    person: Mapped["Person"] = cast(
        Mapped["Person"],
        db.relationship(
            "Person",
        ),
    )
    event: Mapped["Event"] = cast(
        Mapped["Event"],
        db.relationship(
            "Event",
            back_populates="attendees",
            lazy="joined",
        ),
    )

    @classmethod
    def find_by_ids(cls, event_id: int, person_id: int) -> Self | None:
        return cls.query.filter(
            cls.event_id == event_id, cls.person_id == person_id
        ).first()
