from marshmallow import ValidationError, fields, Schema, EXCLUDE

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class AddHousehold(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=_not_blank)
    photo = fields.String()
    link = fields.String()
    description = fields.String()
    language = fields.String()
    view_ordering = fields.List(fields.String)
    hidden_views = fields.List(fields.String)
    member = fields.List(fields.Integer)


class UpdateHousehold(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(validate=_not_blank)
    photo = fields.String()
    link = fields.String()
    description = fields.String()
    language = fields.String()
    view_ordering = fields.List(fields.String)
    hidden_views = fields.List(fields.String)


class UpdateHouseholdMember(Schema):
    class Meta:
        unknown = EXCLUDE

    admin = fields.Boolean()
