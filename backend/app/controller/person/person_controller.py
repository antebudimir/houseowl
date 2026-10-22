from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required
from datetime import datetime, timezone

from app import socketio
from app.errors import NotFoundRequest
from app.helpers import validate_args, authorize_household
from app.models import Person, HouseholdMember
from .schemas import GetPersons, AddPerson, UpdatePerson

person = Blueprint("person", __name__)
personHousehold = Blueprint("person", __name__)


@personHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(GetPersons)
def getPersons(args, household_id):
    return jsonify(
        [
            p.obj_to_full_dict()
            for p in Person.query.filter(Person.household_id == household_id)
            .order_by(Person.name)
            .all()
        ]
    )


@personHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddPerson)
def addPerson(args, household_id):
    person = Person()
    person.name = args["name"]
    person.household_id = household_id
    if "role" in args:
        person.role = args["role"]
    if "phone" in args:
        person.phone = args["phone"]
    if "email" in args:
        person.email = args["email"]
    if "notes" in args:
        person.notes = args["notes"]
    if "birthday" in args:
        person.birthday = datetime.fromtimestamp(
            args["birthday"] / 1000, timezone.utc
        ).date()
    if "user_id" in args and args["user_id"] is not None:
        member = HouseholdMember.find_by_ids(household_id, args["user_id"])
        if not member:
            raise NotFoundRequest()
        person.user_id = args["user_id"]
    person.save()
    socketio.emit(
        "person:update",
        {"person": person.obj_to_full_dict()},
        to="household/" + str(household_id),
    )
    return jsonify(person.obj_to_full_dict())


@person.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdatePerson)
def updatePerson(args, id):
    person = Person.find_by_id(id)
    if not person:
        raise NotFoundRequest()
    person.checkAuthorized()

    if "name" in args:
        person.name = args["name"]
    if "role" in args:
        person.role = args["role"]
    if "phone" in args:
        person.phone = args["phone"]
    if "email" in args:
        person.email = args["email"]
    if "notes" in args:
        person.notes = args["notes"]
    if "birthday" in args:
        if args["birthday"] is None:
            person.birthday = None
        else:
            person.birthday = datetime.fromtimestamp(
                args["birthday"] / 1000, timezone.utc
            ).date()
    if "user_id" in args:
        if args["user_id"] is None:
            person.user_id = None
        else:
            member = HouseholdMember.find_by_ids(person.household_id, args["user_id"])
            if not member:
                raise NotFoundRequest()
            person.user_id = args["user_id"]

    person.save()
    socketio.emit(
        "person:update",
        {"person": person.obj_to_full_dict()},
        to="household/" + str(person.household_id),
    )
    return jsonify(person.obj_to_full_dict())


@person.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deletePerson(id):
    person = Person.find_by_id(id)
    if not person:
        raise NotFoundRequest()
    person.checkAuthorized()
    household_id = person.household_id
    person.delete()
    socketio.emit(
        "person:update",
        {"person": None},
        to="household/" + str(household_id),
    )
    return jsonify({"msg": "DONE"})