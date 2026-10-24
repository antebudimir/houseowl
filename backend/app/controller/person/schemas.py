from marshmallow import fields, Schema


class GetPersons(Schema):
    pass


class AddPerson(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    role = fields.String(allow_none=True, validate=lambda a: a and not a.isspace())
    phone = fields.String(allow_none=True, validate=lambda a: a and not a.isspace())
    email = fields.String(allow_none=True, validate=lambda a: a and not a.isspace())
    notes = fields.String(allow_none=True)
    gift_idea = fields.String(allow_none=True)
    birthday = fields.Integer(allow_none=True, validate=lambda a: a >= 0)
    user_id = fields.Integer(allow_none=True, validate=lambda a: a > 0)


class UpdatePerson(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())
    role = fields.String(validate=lambda a: a and not a.isspace(), allow_none=True)
    phone = fields.String(validate=lambda a: a and not a.isspace(), allow_none=True)
    email = fields.String(validate=lambda a: a and not a.isspace(), allow_none=True)
    notes = fields.String(allow_none=True)
    gift_idea = fields.String(allow_none=True)
    birthday = fields.Integer(validate=lambda a: a >= 0, allow_none=True)
    user_id = fields.Integer(allow_none=True, validate=lambda a: a > 0)