from marshmallow import ValidationError, fields, Schema

from app.config import EMAIL_MANDATORY

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


class Login(Schema):
    username = fields.String(required=True, validate=_not_blank)
    password = fields.String(
        required=True,
        validate=_not_blank,
        load_only=True,
    )
    device = fields.String(
        required=False,
        validate=_not_blank,
        load_only=True,
    )


class Signup(Schema):
    username = fields.String(
        required=True, validate=_no_at
    )
    email = fields.String(
        required=EMAIL_MANDATORY,
        validate=_has_at,
        load_only=True,
    )
    name = fields.String(required=True, validate=_not_blank)
    password = fields.String(
        required=True,
        validate=_not_blank,
        load_only=True,
    )
    device = fields.String(
        required=False,
        validate=_not_blank,
        load_only=True,
    )


class CreateLongLivedToken(Schema):
    device = fields.String(
        required=True,
        validate=_not_blank,
        load_only=True,
    )


class GetOIDCLoginUrl(Schema):
    provider = fields.String(
        validate=_not_blank,
        load_only=True,
    )
    houseowl_scheme = fields.Boolean(
        required=False,
        load_default=False,
        load_only=True,
    )
    kitchenowl_scheme = fields.Boolean(  # deprecated alias, kept for old clients
        required=False,
        load_default=False,
        load_only=True,
        data_key="kitchenowl_scheme",
    )


class LoginOIDC(Schema):
    state = fields.String(
        validate=_not_blank,
        required=True,
        load_only=True,
    )
    code = fields.String(
        validate=_not_blank,
        required=True,
        load_only=True,
    )
    device = fields.String(
        validate=_not_blank,
        required=False,
        load_only=True,
    )
