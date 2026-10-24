from marshmallow import ValidationError, fields, Schema

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class GetNotes(Schema):
    search = fields.String()


class AddNote(Schema):
    title = fields.String(required=True, validate=_not_blank)
    body = fields.String()
    tags = fields.List(fields.String(), validate=lambda a: a is not None)


class UpdateNote(Schema):
    title = fields.String(validate=_not_blank)
    body = fields.String(allow_none=True)
    tags = fields.List(fields.String(), validate=lambda a: a is not None)
