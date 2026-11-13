from marshmallow import ValidationError, EXCLUDE, fields, Schema, validate


def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


def _non_negative(a):
    # Reminder lead time in minutes; None clears the reminder.
    if a is not None and a < 0:
        raise ValidationError("Must be zero or greater.")


class AddEvent(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=_not_blank)
    description = fields.String(allow_none=True)
    location = fields.String(allow_none=True)
    start = fields.Integer(required=True)
    end = fields.Integer(required=True)
    all_day = fields.Boolean(load_default=False)
    reminder_minutes = fields.Integer(allow_none=True, validate=_non_negative)
    attendees = fields.List(fields.Integer(), load_default=list)


class UpdateEvent(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(validate=_not_blank)
    description = fields.String(allow_none=True)
    location = fields.String(allow_none=True)
    start = fields.Integer()
    end = fields.Integer()
    all_day = fields.Boolean()
    reminder_minutes = fields.Integer(allow_none=True, validate=_non_negative)
    attendees = fields.List(fields.Integer())


class ConflictQuery(Schema):
    class Meta:
        unknown = EXCLUDE

    start = fields.Integer(required=True)
    end = fields.Integer(required=True)
    attendees = fields.List(fields.Integer(), load_default=list)
