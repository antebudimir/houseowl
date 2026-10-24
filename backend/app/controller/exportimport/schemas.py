from marshmallow import ValidationError, EXCLUDE, fields, Schema, validate

from app.models import BARCODE_FORMATS

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class ImportSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    class Item(Schema):
        name = fields.String(required=True, validate=_not_blank)
        category = fields.String(validate=_not_blank)
        icon = fields.String()

    items = fields.List(fields.Nested(Item))
    member = fields.List(fields.String())
    shoppinglists = fields.List(fields.String())

    class DocumentFile(Schema):
        filename = fields.String(required=True)
        data = fields.String()

    class Document(Schema):
        title = fields.String(required=True, validate=_not_blank)
        notes = fields.String(allow_none=True)
        expires_at = fields.String(allow_none=True)
        contact = fields.String(allow_none=True)
        file = fields.Nested("DocumentFile", allow_none=True)

    documents = fields.List(fields.Nested(Document))

    class LoyaltyCard(Schema):
        store_name = fields.String(
            required=True, validate=_not_blank
        )
        card_number = fields.String(
            required=True, validate=_not_blank
        )
        barcode_format = fields.String(
            required=True,
            validate=validate.OneOf(
                sorted(BARCODE_FORMATS), error="Unsupported barcode format."
            ),
        )
        notes = fields.String(allow_none=True)

    loyalty_cards = fields.List(fields.Nested(LoyaltyCard))
