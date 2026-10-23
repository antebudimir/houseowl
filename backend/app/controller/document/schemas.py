from marshmallow import EXCLUDE, fields, Schema, ValidationError, validate


def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Must not be blank.")
    return True


class GetDocuments(Schema):
    class Meta:
        unknown = EXCLUDE

    search = fields.String()
    expiring_within = fields.String(
        validate=validate.Regexp(r"^\d+d$", error="Must be like '30d'.")
    )


class AddDocument(Schema):
    class Meta:
        unknown = EXCLUDE

    title = fields.String(required=True, validate=_not_blank)
    notes = fields.String(allow_none=True)
    expires_at = fields.Integer(allow_none=True)
    file_id = fields.String(allow_none=True)
    contact_id = fields.Integer(allow_none=True)


class UpdateDocument(Schema):
    class Meta:
        unknown = EXCLUDE

    title = fields.String(validate=_not_blank)
    notes = fields.String(allow_none=True)
    expires_at = fields.Integer(allow_none=True)
    file_id = fields.String(allow_none=True)
    contact_id = fields.Integer(allow_none=True)
