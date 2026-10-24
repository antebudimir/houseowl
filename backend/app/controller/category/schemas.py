from marshmallow import ValidationError, fields, Schema, EXCLUDE

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class AddCategory(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=_not_blank)


class UpdateCategory(Schema):
    name = fields.String(validate=_not_blank)
    ordering = fields.Integer(validate=lambda i: i >= 0)

    # if set this merges the specified category into this category thus combining them to one
    merge_category_id = fields.Integer(
        validate=lambda a: a > 0,
        allow_none=True,
    )


class DeleteCategory(Schema):
    name = fields.String(required=True, validate=_not_blank)
