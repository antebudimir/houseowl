from marshmallow import EXCLUDE, fields, Schema, validate

from app.models import BARCODE_FORMATS


class ImportSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    class Item(Schema):
        name = fields.String(required=True, validate=lambda a: a and not a.isspace())
        category = fields.String(validate=lambda a: a and not a.isspace())
        icon = fields.String()

    items = fields.List(fields.Nested(Item))
    member = fields.List(fields.String())
    shoppinglists = fields.List(fields.String())

    class DocumentFile(Schema):
        filename = fields.String(required=True)
        data = fields.String()

    class Document(Schema):
        title = fields.String(required=True, validate=lambda a: a and not a.isspace())
        notes = fields.String(allow_none=True)
        expires_at = fields.String(allow_none=True)
        contact = fields.String(allow_none=True)
        file = fields.Nested("DocumentFile", allow_none=True)

    documents = fields.List(fields.Nested(Document))

    class LoyaltyCard(Schema):
        store_name = fields.String(
            required=True, validate=lambda a: a and not a.isspace()
        )
        card_number = fields.String(
            required=True, validate=lambda a: a and not a.isspace()
        )
        barcode_format = fields.String(
            required=True,
            validate=validate.OneOf(
                sorted(BARCODE_FORMATS), error="Unsupported barcode format."
            ),
        )
        notes = fields.String(allow_none=True)

    loyalty_cards = fields.List(fields.Nested(LoyaltyCard))
