from marshmallow import EXCLUDE, fields, Schema


class ImportSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    class Item(Schema):
        name = fields.String(required=True, validate=lambda a: a and not a.isspace())
        category = fields.String(validate=lambda a: a and not a.isspace())
        icon = fields.String()

    items = fields.List(fields.Nested(Item))
    member = fields.List(fields.String())
    shoppinglists = fields.List(fields.String())
