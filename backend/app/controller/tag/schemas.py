from marshmallow import ValidationError, fields, Schema

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class AddTag(Schema):
    name = fields.String(required=True, validate=_not_blank)


class UpdateTag(Schema):
    name = fields.String(validate=_not_blank)

    # if set this merges the specified tag into this tag thus combining them to one
    merge_tag_id = fields.Integer(
        validate=lambda a: a > 0,
        allow_none=True,
    )
