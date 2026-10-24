from marshmallow import fields, Schema, EXCLUDE


class GetShoppingLists(Schema):
    orderby = fields.Integer()
    recent_limit = fields.Integer(load_default=9, validate=lambda x: x > 0 and x <= 120)


class AddItemByName(Schema):
    name = fields.String(required=True)
    description = fields.String()


class CreateList(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())


class UpdateList(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())


class GetItems(Schema):
    orderby = fields.Integer()


class GetRecentItems(Schema):
    # Align deprecated endpoint limit with list endpoint (<=120)
    limit = fields.Integer(load_default=9, validate=lambda x: x > 0 and x <= 120)


class UpdateDescription(Schema):
    description = fields.String(load_default="")


class RemoveItem(Schema):
    item_id = fields.Integer(
        required=True,
    )
    removed_at = fields.Integer()


class RemoveItems(Schema):
    class RemovedItem(Schema):
        class Meta:
            unknown = EXCLUDE

        item_id = fields.Integer(
            required=True,
        )
        removed_at = fields.Integer()

    items = fields.List(fields.Nested(RemovedItem))
