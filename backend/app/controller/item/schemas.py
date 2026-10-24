from marshmallow import ValidationError, fields, Schema, EXCLUDE

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class SearchByNameRequest(Schema):
    query = fields.String(required=True, validate=_not_blank)


class UpdateItem(Schema):
    class Meta:
        unknown = EXCLUDE

    class Category(Schema):
        class Meta:
            unknown = EXCLUDE

        id = fields.Integer(required=True, validate=lambda a: a > 0)
        name = fields.String(validate=lambda a: not a or a and not a.isspace())

    category = fields.Nested(Category(), allow_none=True)
    icon = fields.String(
        validate=lambda a: not a or not a.isspace(),
        allow_none=True,
    )
    name = fields.String(
        validate=lambda a: not a or not a.isspace(),
        allow_none=True,
    )

    # if set this merges the specified item into this item thus combining them to one
    merge_item_id = fields.Integer(
        validate=lambda a: a > 0,
        allow_none=True,
    )


class AddItem(Schema):
    class Meta:
        unknown = EXCLUDE

    class Category(Schema):
        class Meta:
            unknown = EXCLUDE

        id = fields.Integer(required=True, validate=lambda a: a > 0)
        name = fields.String(validate=lambda a: not a or a and not a.isspace())

    category = fields.Nested(Category(), allow_none=True)
    icon = fields.String(
        validate=lambda a: not a or not a.isspace(),
        allow_none=True,
    )
    name = fields.String(
        validate=lambda a: not a or not a.isspace(),
        allow_none=False,
        required=True,
    )
