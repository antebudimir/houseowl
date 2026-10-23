from typing import TYPE_CHECKING, Any, Optional, Self

from sqlalchemy.orm import Mapped

from app import db
from app.helpers import DbModelAuthorizeMixin

Model = db.Model
if TYPE_CHECKING:
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase

# Single source of truth for the server-side barcode-format whitelist. Kept
# in sync with the client's `barcode_formats.dart` enum (a client test asserts
# the two match exactly) and with the writers supported by the Dart `barcode`
# package used for rendering.
BARCODE_FORMATS = frozenset(
    {
        "code39",
        "code93",
        "code128",
        "ean13",
        "ean8",
        "isbn",
        "itf",
        "upca",
        "upce",
        "codabar",
        "qr",
        "aztec",
        "dataMatrix",
        "pdf417",
        "rm4scc",
        "telepen",
    }
)


class LoyaltyCard(Model, DbModelAuthorizeMixin):
    __tablename__ = "loyalty_card"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    store_name: Mapped[str] = db.Column(db.String(255), nullable=False)
    card_number: Mapped[str] = db.Column(db.String(255), nullable=False)
    barcode_format: Mapped[str] = db.Column(db.String(32), nullable=False)
    notes: Mapped[Optional[str]] = db.Column(db.Text, nullable=True)
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    @classmethod
    def find_by_id(cls, id: int) -> Optional[Self]:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def all_from_household(cls, household_id: int) -> list[Self]:
        return (
            cls.query.filter(cls.household_id == household_id)
            .order_by(cls.store_name.asc(), cls.id.asc())
            .all()
        )

    @classmethod
    def search(cls, household_id: int, query: str) -> list[Self]:
        # Server-side ILIKE over store name and notes, mirroring Document.search.
        looking_for = f"%{query}%"
        return (
            cls.query.filter(cls.household_id == household_id)
            .filter(
                db.or_(
                    cls.store_name.ilike(looking_for),
                    cls.notes.ilike(looking_for),
                )
            )
            .order_by(cls.store_name.asc(), cls.id.asc())
            .all()
        )

    def obj_to_full_dict(self) -> dict[str, Any]:
        return super().obj_to_dict()

    def obj_to_export_dict(self) -> dict[str, Any]:
        # Portable representation: no ids or household reference.
        return {
            "store_name": self.store_name,
            "card_number": self.card_number,
            "barcode_format": self.barcode_format,
            "notes": self.notes,
        }

