from marshmallow import fields, Schema


class GetNotes(Schema):
    search = fields.String()


class AddNote(Schema):
    title = fields.String(required=True, validate=lambda a: a and not a.isspace())
    body = fields.String()
    tags = fields.List(fields.String(), validate=lambda a: a is not None)


class UpdateNote(Schema):
    title = fields.String(validate=lambda a: a and not a.isspace())
    body = fields.String(allow_none=True)
    tags = fields.List(fields.String(), validate=lambda a: a is not None)
