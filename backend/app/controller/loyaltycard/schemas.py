from marshmallow import EXCLUDE, Schema, ValidationError, fields, validate

from app.models import BARCODE_FORMATS


def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Must not be blank.")
    return True


class GetLoyaltyCards(Schema):
    class Meta:
        unknown = EXCLUDE

    search = fields.String()


class AddLoyaltyCard(Schema):
    class Meta:
        unknown = EXCLUDE

    store_name = fields.String(required=True, validate=_not_blank)
    card_number = fields.String(required=True, validate=_not_blank)
    barcode_format = fields.String(
        required=True,
        validate=validate.OneOf(
            sorted(BARCODE_FORMATS), error="Unsupported barcode format."
        ),
    )
    notes = fields.String(allow_none=True)


class UpdateLoyaltyCard(Schema):
    class Meta:
        unknown = EXCLUDE

    store_name = fields.String(validate=_not_blank)
    card_number = fields.String(validate=_not_blank)
    barcode_format = fields.String(
        validate=validate.OneOf(
            sorted(BARCODE_FORMATS), error="Unsupported barcode format."
        )
    )
    notes = fields.String(allow_none=True)