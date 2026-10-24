from marshmallow import ValidationError, fields, Schema

def _not_blank(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace():
        raise ValidationError("Not a valid string.")


def _no_at(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace() or "@" in a:
        raise ValidationError("Not a valid string.")


def _has_at(a):
    # marshmallow only fails on raised errors, not on a falsy return value.
    if not a or a.isspace() or "@" not in a:
        raise ValidationError("Not a valid string.")


class CreateUser(Schema):
    name = fields.String(required=True, validate=_not_blank)
    username = fields.String(
        required=True,
        validate=_no_at,
        load_only=True,
    )
    email = fields.String(
        required=False,
        validate=_has_at,
        load_only=True,
    )
    password = fields.String(
        required=True,
        validate=_not_blank,
        load_only=True,
    )


class UpdateUser(Schema):
    name = fields.String(validate=_not_blank)
    photo = fields.String()
    username = fields.String(
        validate=_no_at,
        load_only=True,
    )
    email = fields.String(
        validate=_has_at,
        load_only=True,
    )
    password = fields.String(
        validate=_not_blank,
        load_only=True,
    )
    admin = fields.Boolean(
        load_only=True,
    )


class SearchByNameRequest(Schema):
    query = fields.String(required=True, validate=_not_blank)


class ConfirmMail(Schema):
    token = fields.String(required=True, validate=_not_blank)


class ResetPassword(Schema):
    token = fields.String(required=True, validate=_not_blank)
    password = fields.String(
        required=True,
        validate=_not_blank,
        load_only=True,
    )


class ForgotPassword(Schema):
    email = fields.String(
        required=True,
        validate=_has_at,
        load_only=True,
    )
