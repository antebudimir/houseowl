from datetime import date

from marshmallow import EXCLUDE, fields, Schema, validate

from app.models.task import RECURRENCE_VALUES


def _not_blank(a):
    return a and not a.isspace()


def _valid_date(a):
    if a is None:
        return
    try:
        date.fromisoformat(a)
    except (ValueError, TypeError) as exc:
        from marshmallow import ValidationError

        raise ValidationError("Not a valid ISO date (YYYY-MM-DD).") from exc


class AddTask(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=_not_blank)
    description = fields.String(allow_none=True)
    priority = fields.Integer(load_default=0, validate=validate.Range(min=0, max=3))
    recurrence = fields.String(
        load_default="none", validate=validate.OneOf(RECURRENCE_VALUES)
    )
    due_date = fields.String(allow_none=True, validate=_valid_date)
    assignee_id = fields.Integer(allow_none=True)
    buy_id = fields.Integer(allow_none=True)
    tags = fields.List(fields.String(), load_default=list)


class UpdateTask(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(validate=_not_blank)
    description = fields.String(allow_none=True)
    status = fields.String(validate=validate.OneOf(("open", "done")))
    priority = fields.Integer(validate=validate.Range(min=0, max=3))
    recurrence = fields.String(validate=validate.OneOf(RECURRENCE_VALUES))
    due_date = fields.String(allow_none=True, validate=_valid_date)
    assignee_id = fields.Integer(allow_none=True)
    buy_id = fields.Integer(allow_none=True)
    tags = fields.List(fields.String())
