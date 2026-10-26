import calendar
from datetime import date, datetime, timedelta, timezone
from typing import Any, List, Optional, Self, TYPE_CHECKING, cast

from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

from .tag import Tag

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, PlannedBuy, Tag, User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


RECURRENCE_VALUES = ("none", "daily", "weekly", "biweekly", "monthly", "yearly")
STATUS_VALUES = ("open", "done")


def _add_months(d: date, months: int) -> date:
    """Advance by whole months, clamping the day (Jan 31 -> Feb 28/29)."""
    month_index = d.month - 1 + months
    year = d.year + month_index // 12
    month = month_index % 12 + 1
    day = min(d.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


def next_due(due: date, recurrence: str, today: Optional[date] = None) -> date:
    """Compute the next due date for a recurring task.

    Schedule-anchored: advances from the original due date (not from the
    completion time) until the result is in the future, so a daily task
    completed days overdue is rescheduled to tomorrow, not gifted a burst
    of catch-up occurrences. Monthly/yearly intervals keep the original
    day-of-month as the anchor (Jan 31 stays on the 31st, clamped to
    Feb 28/29, and returns to the 31st in March).
    """
    if today is None:
        today = date.today()

    if recurrence == "monthly" or recurrence == "yearly":
        step = 1 if recurrence == "monthly" else 12
        months = step
        while True:
            candidate = _add_months(due, months)
            if candidate > today:
                return candidate
            months += step

    current = due
    while current <= today:
        if recurrence == "daily":
            current = current + timedelta(days=1)
        elif recurrence == "weekly":
            current = current + timedelta(days=7)
        elif recurrence == "biweekly":
            current = current + timedelta(days=14)
        else:
            return current
    return current


class Task(Model, DbModelAuthorizeMixin):
    __tablename__ = "task"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    description: Mapped[Optional[str]] = db.Column(db.Text, nullable=True)
    status: Mapped[str] = db.Column(db.String(16), default="open", nullable=False)
    priority: Mapped[int] = db.Column(db.Integer, default=0, nullable=False)
    recurrence: Mapped[str] = db.Column(db.String(16), default="none", nullable=False)
    # Date, not DateTime: due dates carry no time component, which removes
    # timezone/DST handling from the recurrence math entirely.
    due_date: Mapped[Optional[date]] = db.Column(db.Date, nullable=True)
    completed_at: Mapped[Optional[datetime]] = db.Column(
        db.DateTime, nullable=True
    )
    # Assignee is a household member (user account), not a directory person.
    assignee_id: Mapped[Optional[int]] = db.Column(
        db.Integer, db.ForeignKey("user.id", ondelete="SET NULL"), nullable=True
    )
    buy_id: Mapped[Optional[int]] = db.Column(
        db.Integer, db.ForeignKey("planned_buy.id", ondelete="SET NULL"), nullable=True
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
    buy: Mapped[Optional["PlannedBuy"]] = cast(
        Mapped[Optional["PlannedBuy"]],
        db.relationship(
            "PlannedBuy",
            uselist=False,
        ),
    )
    tags: Mapped[List["TaskTags"]] = cast(
        Mapped[List["TaskTags"]],
        db.relationship(
            "TaskTags",
            back_populates="task",
            cascade="all, delete-orphan",
            lazy="joined",
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = super().obj_to_dict()
        # due_date is a bare calendar date; serialize as ISO so the client
        # never has to guess a timezone.
        res["due_date"] = self.due_date.isoformat() if self.due_date else None
        # Keys are always present (null when unset) so the client gets a
        # consistent shape — including after a SET NULL cascade.
        res["assignee"] = self.assignee.obj_to_dict() if self.assignee else None
        res["buy"] = self.buy.obj_to_dict() if self.buy else None
        res["tags"] = [con.tag.obj_to_dict() for con in self.tags]
        return res

    def complete(self) -> Optional[Self]:
        """Mark done and materialize the next occurrence for recurring tasks.

        Returns the persisted successor task, or None. Idempotent: a task
        that is already done never spawns a second clone. Completion does
        not touch the linked planned buy's status (one tool, one purpose).
        """
        if self.status != "done":
            self.status = "done"
        if self.completed_at is None:
            self.completed_at = datetime.now(timezone.utc)
        self.save()
        if self.recurrence not in RECURRENCE_VALUES or self.recurrence == "none":
            return None

        successor = Task()
        successor.household_id = self.household_id
        successor.name = self.name
        successor.description = self.description
        successor.priority = self.priority
        successor.recurrence = self.recurrence
        successor.assignee_id = self.assignee_id
        successor.buy_id = self.buy_id
        successor.due_date = next_due(
            self.due_date if self.due_date else date.today(), self.recurrence
        )
        successor.save()
        for con in self.tags:
            TaskTags(task=successor, tag=con.tag).save()
        return successor

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def all_from_household(cls, household_id: int) -> list[Self]:
        tasks = cls.query.filter(cls.household_id == household_id).all()
        # Open first, due-date order (nulls last), then priority desc.
        return sorted(
            tasks,
            key=lambda t: (
                t.status == "done",
                t.due_date is None,
                t.due_date or date.max,
                -t.priority,
                t.id,
            ),
        )


class TaskTags(Model):
    __tablename__ = "task_tags"

    task_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("task.id"), primary_key=True
    )
    tag_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("tag.id"), primary_key=True
    )

    tag: Mapped["Tag"] = cast(
        Mapped["Tag"],
        db.relationship(
            "Tag",
            back_populates="tasks",
        ),
    )
    task: Mapped["Task"] = cast(
        Mapped["Task"],
        db.relationship(
            "Task",
            back_populates="tags",
            lazy="joined",
        ),
    )

    _name: Mapped[str] = db.column_property(
        db.select(Tag.name).where(Tag.id == tag_id).scalar_subquery()
    )

    @classmethod
    def find_by_ids(cls, task_id: int, tag_id: int) -> Self | None:
        return cls.query.filter(
            cls.task_id == task_id, cls.tag_id == tag_id
        ).first()
