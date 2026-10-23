from datetime import datetime, timezone

from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required

from app import socketio
from app.errors import NotFoundRequest
from app.helpers import validate_args, authorize_household
from app.models import Event, EventAttendee, Person
from .schemas import AddEvent, UpdateEvent

eventBP = Blueprint("event", __name__)
eventHousehold = Blueprint("event", __name__)


def _parse_ms(raw):
    # Naive UTC to match how db.DateTime values come back from the DB.
    return datetime.fromtimestamp(raw / 1000, timezone.utc).replace(tzinfo=None)


def _set_attendees(event, household_id, attendee_ids):
    for con in event.attendees:
        if con.person_id not in attendee_ids:
            con.delete()
    for person_id in attendee_ids:
        person = Person.find_by_id(person_id)
        if not person or person.household_id != household_id:
            raise NotFoundRequest()
        con = EventAttendee.find_by_ids(event.id, person.id)
        if not con:
            EventAttendee(event=event, person=person).save()


def _emit_update(event_or_none, household_id):
    payload = event_or_none.obj_to_full_dict() if event_or_none else None
    socketio.emit(
        "event:update",
        {"event": payload},
        to="household/" + str(household_id),
    )


def _conflict_response(events):
    return (
        jsonify(
            [
                {
                    "id": e.id,
                    "name": e.name,
                    "start": e.start,
                    "end": e.end,
                    "attendees": [
                        con.person.obj_to_dict() for con in e.attendees
                    ],
                }
                for e in events
            ]
        ),
        409,
    )


@eventHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getEvents(household_id):
    events = Event.all_from_household(household_id)
    # Optional range filter on the half-open [from, to) window, in epoch ms.
    range_from = request.args.get("from", type=int)
    range_to = request.args.get("to", type=int)
    if range_from is not None:
        bound = _parse_ms(range_from)
        events = [e for e in events if e.end > bound]
    if range_to is not None:
        bound = _parse_ms(range_to)
        events = [e for e in events if e.start < bound]
    return jsonify([e.obj_to_full_dict() for e in events])


@eventHousehold.route("/conflicts", methods=["GET"])
@jwt_required()
@authorize_household()
def getEventConflicts(household_id):
    # Manual parsing: repeated ?attendee=<id> params, epoch-ms bounds.
    start = request.args.get("start", type=int)
    end = request.args.get("end", type=int)
    if start is None or end is None:
        return jsonify({"msg": "start and end are required."}), 400
    attendee_ids = request.args.getlist("attendee", type=int)
    conflicts = Event.find_conflicts(
        household_id, _parse_ms(start), _parse_ms(end), attendee_ids
    )
    return jsonify(
        [
            {
                "id": e.id,
                "name": e.name,
                "start": e.start,
                "end": e.end,
                "attendees": [con.person.obj_to_dict() for con in e.attendees],
            }
            for e in conflicts
        ]
    )


@eventHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddEvent)
def addEvent(args, household_id):
    start = _parse_ms(args["start"])
    end = _parse_ms(args["end"])
    if end <= start:
        return jsonify({"msg": "End must be after start."}), 400

    conflicts = Event.find_conflicts(
        household_id, start, end, args["attendees"]
    )
    if conflicts:
        return _conflict_response(conflicts)

    event = Event()
    event.household_id = household_id
    event.name = args["name"]
    event.start = start
    event.end = end
    event.all_day = args["all_day"]
    if args.get("description") is not None:
        event.description = args["description"]
    if args.get("location") is not None:
        event.location = args["location"]
    event.save()
    if args["attendees"]:
        _set_attendees(event, household_id, args["attendees"])
    _emit_update(event, household_id)
    return jsonify(event.obj_to_full_dict())


@eventBP.route("/<int:id>", methods=["GET"])
@jwt_required()
def getEvent(id):
    event = Event.find_by_id(id)
    if not event:
        raise NotFoundRequest()
    event.checkAuthorized()
    return jsonify(event.obj_to_full_dict())


@eventBP.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateEvent)
def updateEvent(args, id):
    event = Event.find_by_id(id)
    if not event:
        raise NotFoundRequest()
    event.checkAuthorized()

    if "name" in args:
        event.name = args["name"]
    if "description" in args:
        event.description = args["description"]
    if "location" in args:
        event.location = args["location"]
    if "all_day" in args:
        event.all_day = args["all_day"]
    if "start" in args:
        event.start = _parse_ms(args["start"])
    if "end" in args:
        event.end = _parse_ms(args["end"])
    if event.end <= event.start:
        return jsonify({"msg": "End must be after start."}), 400

    attendee_ids = args.get("attendees")
    if (
        "start" in args
        or "end" in args
        or attendee_ids is not None
    ):
        if attendee_ids is None:
            attendee_ids = [con.person_id for con in event.attendees]
        conflicts = Event.find_conflicts(
            event.household_id,
            event.start,
            event.end,
            attendee_ids,
            exclude_id=event.id,
        )
        if conflicts:
            return _conflict_response(conflicts)
    if attendee_ids is not None:
        _set_attendees(event, event.household_id, attendee_ids)

    event.save()
    _emit_update(event, event.household_id)
    return jsonify(event.obj_to_full_dict())


@eventBP.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteEvent(id):
    event = Event.find_by_id(id)
    if not event:
        raise NotFoundRequest()
    event.checkAuthorized()
    household_id = event.household_id
    event.delete()
    _emit_update(None, household_id)
    return jsonify({"msg": "DONE"})
