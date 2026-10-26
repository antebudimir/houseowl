from datetime import datetime, timezone

from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required

from app import socketio
from app.errors import InvalidUsage, NotFoundRequest
from app.helpers import validate_args, authorize_household
from app.models import Document, File, HouseholdMember
from .schemas import GetDocuments, AddDocument, UpdateDocument

document = Blueprint("document", __name__)
documentHousehold = Blueprint("document", __name__)


@documentHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(GetDocuments)
def getDocuments(args, household_id):
    if args.get("search"):
        return jsonify(
            [d.obj_to_full_dict() for d in Document.search(household_id, args["search"])]
        )
    if args.get("expiring_within"):
        days = int(args["expiring_within"].removesuffix("d"))
        return jsonify(
            [
                d.obj_to_full_dict()
                for d in Document.find_expiring(household_id, days)
            ]
        )
    return jsonify(
        [
            d.obj_to_full_dict()
            for d in Document.query.filter(Document.household_id == household_id)
            .order_by(Document.updated_at.desc(), Document.id.desc())
            .all()
        ]
    )


def _parse_expires_at(args):
    if "expires_at" not in args or args["expires_at"] is None:
        return None
    return datetime.fromtimestamp(args["expires_at"] / 1000, timezone.utc)


def _resolve_owner(args, household_id):
    if not args.get("owner_id"):
        return None
    member = HouseholdMember.find_by_ids(household_id, args["owner_id"])
    if not member:
        raise InvalidUsage("Invalid owner_id")
    return member.user


def _resolve_file(args):
    if not args.get("file_id"):
        return None
    file = File.find(args["file_id"])
    if not file:
        raise InvalidUsage("Invalid file_id")
    return file


@documentHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddDocument)
def addDocument(args, household_id):
    document = Document()
    document.title = args["title"]
    document.household_id = household_id
    document.notes = args.get("notes")
    document.expires_at = _parse_expires_at(args)
    document.file = _resolve_file(args)
    document.owner = _resolve_owner(args, household_id)
    document.save()
    socketio.emit(
        "document:update",
        {"document": document.obj_to_full_dict()},
        to="household/" + str(household_id),
    )
    return jsonify(document.obj_to_full_dict())


@document.route("/<int:id>", methods=["GET"])
@jwt_required()
def getDocument(id):
    document = Document.find_by_id(id)
    if not document:
        raise NotFoundRequest()
    document.checkAuthorized()
    return jsonify(document.obj_to_full_dict())


@document.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateDocument)
def updateDocument(args, id):
    document = Document.find_by_id(id)
    if not document:
        raise NotFoundRequest()
    document.checkAuthorized()

    if "title" in args:
        document.title = args["title"]
    if "notes" in args:
        document.notes = args["notes"]
    if "expires_at" in args:
        document.expires_at = _parse_expires_at(args)
    if "file_id" in args:
        document.file = _resolve_file(args)
    if "owner_id" in args:
        document.owner = _resolve_owner(args, document.household_id)
    document.save()
    socketio.emit(
        "document:update",
        {"document": document.obj_to_full_dict()},
        to="household/" + str(document.household_id),
    )
    return jsonify(document.obj_to_full_dict())


@document.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteDocument(id):
    document = Document.find_by_id(id)
    if not document:
        raise NotFoundRequest()
    document.checkAuthorized()
    household_id = document.household_id
    file = document.file
    document.delete()
    if file:
        # A document's file is meaningless without the document; matches the
        # household-photo lifecycle otherwise used for File rows.
        file.delete()
    socketio.emit(
        "document:update",
        {"document": None},
        to="household/" + str(household_id),
    )
    return jsonify({"msg": "DONE"})
