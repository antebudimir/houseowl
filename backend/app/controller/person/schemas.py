from marshmallow import ValidationError, fields, Schema

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class GetPersons(Schema):
    pass


class AddPerson(Schema):
    name = fields.String(required=True, validate=_not_blank)
    role = fields.String(allow_none=True, validate=_not_blank)
    phone = fields.String(allow_none=True, validate=_not_blank)
    email = fields.String(allow_none=True, validate=_not_blank)
    notes = fields.String(allow_none=True)
    gift_idea = fields.String(allow_none=True)
    birthday = fields.Integer(allow_none=True, validate=lambda a: a >= 0)
    user_id = fields.Integer(allow_none=True, validate=lambda a: a > 0)


class UpdatePerson(Schema):
    name = fields.String(validate=_not_blank)
    role = fields.String(validate=_not_blank, allow_none=True)
    phone = fields.String(validate=_not_blank, allow_none=True)
    email = fields.String(validate=_not_blank, allow_none=True)
    notes = fields.String(allow_none=True)
    gift_idea = fields.String(allow_none=True)
    birthday = fields.Integer(validate=lambda a: a >= 0, allow_none=True)
    user_id = fields.Integer(allow_none=True, validate=lambda a: a > 0)