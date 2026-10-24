from marshmallow import ValidationError, fields, Schema

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


def _no_at(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace() or "@" in a:
        raise ValidationError("Not a valid string.")


class OnboardSchema(Schema):
    name = fields.String(required=True, validate=_not_blank)
    username = fields.String(
        required=True,
        validate=_no_at,
    )
    password = fields.String(
        required=True,
        validate=_not_blank,
        load_only=True,
    )
    device = fields.String(
        required=False,
        validate=_not_blank,
        load_only=True,
    )
