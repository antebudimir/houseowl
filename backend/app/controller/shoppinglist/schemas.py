from marshmallow import ValidationError, fields, Schema, EXCLUDE

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class GetShoppingLists(Schema):
    orderby = fields.Integer()
    recent_limit = fields.Integer(load_default=9, validate=lambda x: x > 0 and x <= 120)


class AddItemByName(Schema):
    name = fields.String(required=True)
    description = fields.String()


class CreateList(Schema):
    name = fields.String(required=True, validate=_not_blank)


class UpdateList(Schema):
    name = fields.String(validate=_not_blank)


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
