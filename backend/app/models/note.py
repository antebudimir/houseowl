from typing import Any, List, Self, TYPE_CHECKING, cast

from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

from .tag import Tag

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, Tag
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Note(Model, DbModelAuthorizeMixin):
    __tablename__ = "note"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    title: Mapped[str] = db.Column(db.String(128), nullable=False)
    body: Mapped[str] = db.Column(db.String, nullable=False, default="")
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
    tags: Mapped[List["NoteTags"]] = cast(
        Mapped[List["NoteTags"]],
        db.relationship(
            "NoteTags",
            back_populates="note",
            cascade="all, delete-orphan",
            lazy="joined",
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = super().obj_to_dict()
        res["tags"] = [con.tag.obj_to_dict() for con in self.tags]
        return res

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def search(cls, household_id: int, query: str) -> list[Self]:
        # Server-side ILIKE over title and body: note bodies are long, so
        # client-side substring filtering would not scale.
        looking_for = f"%{query}%"
        return (
            cls.query.filter(cls.household_id == household_id)
            .filter(cls.title.ilike(looking_for) | cls.body.ilike(looking_for))
            .order_by(cls.updated_at.desc(), cls.id.desc())
            .all()
        )


class NoteTags(Model):
    __tablename__ = "note_tags"

    note_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("note.id"), primary_key=True
    )
    tag_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("tag.id"), primary_key=True
    )

    tag: Mapped["Tag"] = cast(
        Mapped["Tag"],
        db.relationship(
            "Tag",
            back_populates="notes",
        ),
    )
    note: Mapped["Note"] = cast(
        Mapped["Note"],
        db.relationship(
            "Note",
            back_populates="tags",
            lazy="joined",
        ),
    )

    _name: Mapped[str] = db.column_property(
        db.select(Tag.name).where(Tag.id == tag_id).scalar_subquery()
    )

    def obj_to_item_dict(self) -> dict[str, Any]:
        res = self.tag.obj_to_dict()
        res["created_at"] = getattr(self, "created_at")
        res["updated_at"] = getattr(self, "updated_at")
        return res

    @classmethod
    def find_by_ids(cls, note_id: int, tag_id: int) -> Self | None:
        return cls.query.filter(
            cls.note_id == note_id, cls.tag_id == tag_id
        ).first()
