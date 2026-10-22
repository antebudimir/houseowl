from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required

from app import socketio
from app.errors import NotFoundRequest
from app.helpers import validate_args, authorize_household
from app.models import Note, Tag, NoteTags
from .schemas import GetNotes, AddNote, UpdateNote

note = Blueprint("note", __name__)
noteHousehold = Blueprint("note", __name__)


@noteHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(GetNotes)
def getNotes(args, household_id):
    if args.get("search"):
        return jsonify(
            [n.obj_to_full_dict() for n in Note.search(household_id, args["search"])]
        )
    return jsonify(
        [
            n.obj_to_full_dict()
            for n in Note.query.filter(Note.household_id == household_id)
            .order_by(Note.updated_at.desc(), Note.id.desc())
            .all()
        ]
    )


@noteHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddNote)
def addNote(args, household_id):
    note = Note()
    note.title = args["title"]
    note.household_id = household_id
    if "body" in args:
        note.body = args["body"]
    note.save()
    if "tags" in args:
        for tagName in args["tags"]:
            tag = Tag.find_by_name(household_id, tagName)
            if not tag:
                tag = Tag.create_by_name(household_id, tagName)
            con = NoteTags()
            con.tag = tag
            con.note = note
            con.save()
    socketio.emit(
        "note:update",
        {"note": note.obj_to_full_dict()},
        to="household/" + str(household_id),
    )
    return jsonify(note.obj_to_full_dict())


@note.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateNote)
def updateNote(args, id):
    note = Note.find_by_id(id)
    if not note:
        raise NotFoundRequest()
    note.checkAuthorized()

    if "title" in args:
        note.title = args["title"]
    if "body" in args:
        note.body = args["body"]
    if "tags" in args:
        for con in note.tags:
            if con.tag.name not in args["tags"]:
                con.delete()
        for tagName in args["tags"]:
            tag = Tag.find_by_name(note.household_id, tagName)
            if not tag:
                tag = Tag.create_by_name(note.household_id, tagName)
            con = NoteTags.find_by_ids(note.id, tag.id)
            if not con:
                con = NoteTags()
                con.tag = tag
                con.note = note
                con.save()
    note.save()
    socketio.emit(
        "note:update",
        {"note": note.obj_to_full_dict()},
        to="household/" + str(note.household_id),
    )
    return jsonify(note.obj_to_full_dict())


@note.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteNote(id):
    note = Note.find_by_id(id)
    if not note:
        raise NotFoundRequest()
    note.checkAuthorized()
    household_id = note.household_id
    note.delete()
    socketio.emit(
        "note:update",
        {"note": None},
        to="household/" + str(household_id),
    )
    return jsonify({"msg": "DONE"})
