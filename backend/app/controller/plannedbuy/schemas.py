from marshmallow import ValidationError, EXCLUDE, fields, Schema, validate

from app.models.planned_buy import PlannedBuy


def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


class AddPlannedBuy(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=_not_blank)
    status = fields.String(
        load_default="idea", validate=validate.OneOf(PlannedBuy.STATUS_VALUES)
    )
    priority = fields.Integer(load_default=0, validate=validate.Range(min=0, max=3))
    category = fields.String(allow_none=True, validate=lambda a: a is None or _not_blank(a))
    target_date = fields.Integer(allow_none=True)
    assignee_id = fields.Integer(allow_none=True)
    actual_price = fields.Float(allow_none=True)


class UpdatePlannedBuy(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(validate=_not_blank)
    status = fields.String(validate=validate.OneOf(PlannedBuy.STATUS_VALUES))
    priority = fields.Integer(validate=validate.Range(min=0, max=3))
    category = fields.String(allow_none=True, validate=lambda a: a is None or _not_blank(a))
    target_date = fields.Integer(allow_none=True)
    assignee_id = fields.Integer(allow_none=True)
    actual_price = fields.Float(allow_none=True)