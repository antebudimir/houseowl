from datetime import datetime, timezone

from flask import Blueprint, jsonify, request
from flask_jwt_extended import current_user, jwt_required

from app import socketio
from app.errors import NotFoundRequest
from app.helpers import validate_args, authorize_household
from app.models import HouseholdMember, PlannedBuy
from .schemas import AddPlannedBuy, UpdatePlannedBuy

plannedBuy = Blueprint("planned_buy", __name__)
plannedBuyHousehold = Blueprint("planned_buy", __name__)


def _parse_target_date(raw):
    return datetime.fromtimestamp(raw / 1000, timezone.utc)


def _set_assignee(buy, household_id, assignee_id):
    if assignee_id is None:
        buy.assignee_id = None
        return
    member = HouseholdMember.find_by_ids(household_id, assignee_id)
    if not member:
        raise NotFoundRequest()
    buy.assignee_id = assignee_id


def _emit_update(buy_or_none, household_id):
    payload = (
        buy_or_none.obj_to_full_dict() if buy_or_none is not None else None
    )
    socketio.emit(
        "planned_buy:update",
        {"planned_buy": payload},
        to="household/" + str(household_id),
    )


@plannedBuyHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getPlannedBuys(household_id):
    buys = PlannedBuy.all_from_household(household_id)
    status = request.args.get("status")
    if status:
        buys = [b for b in buys if b.status == status]
    if request.args.get("assignee") == "me":
        buys = [b for b in buys if b.assignee_id == current_user.id]
    return jsonify([b.obj_to_full_dict() for b in buys])


@plannedBuyHousehold.route("/categories", methods=["GET"])
@jwt_required()
@authorize_household()
def getPlannedBuyCategories(household_id):
    return jsonify(PlannedBuy.all_categories(household_id))


@plannedBuyHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddPlannedBuy)
def addPlannedBuy(args, household_id):
    buy = PlannedBuy()
    buy.household_id = household_id
    buy.name = args["name"]
    buy.apply_status(args["status"])
    buy.priority = args["priority"]
    if args.get("category") is not None:
        buy.category = args["category"]
    if args.get("target_date") is not None:
        buy.target_date = _parse_target_date(args["target_date"])
    if args.get("actual_price") is not None:
        buy.actual_price = args["actual_price"]
    if args.get("assignee_id") is not None:
        _set_assignee(buy, household_id, args["assignee_id"])
    buy.save()
    _emit_update(buy, household_id)
    return jsonify(buy.obj_to_full_dict())


@plannedBuy.route("/<int:id>", methods=["GET"])
@jwt_required()
def getPlannedBuy(id):
    buy = PlannedBuy.find_by_id(id)
    if not buy:
        raise NotFoundRequest()
    buy.checkAuthorized()
    return jsonify(buy.obj_to_full_dict())


@plannedBuy.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdatePlannedBuy)
def updatePlannedBuy(args, id):
    buy = PlannedBuy.find_by_id(id)
    if not buy:
        raise NotFoundRequest()
    buy.checkAuthorized()

    if "name" in args:
        buy.name = args["name"]
    if "status" in args:
        buy.apply_status(args["status"])
    if "priority" in args:
        buy.priority = args["priority"]
    if "category" in args:
        buy.category = args["category"]
    if "target_date" in args:
        buy.target_date = (
            _parse_target_date(args["target_date"])
            if args["target_date"] is not None
            else None
        )
    if "actual_price" in args:
        buy.actual_price = args["actual_price"]
    if "assignee_id" in args:
        _set_assignee(buy, buy.household_id, args["assignee_id"])

    buy.save()
    _emit_update(buy, buy.household_id)
    return jsonify(buy.obj_to_full_dict())


@plannedBuy.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deletePlannedBuy(id):
    buy = PlannedBuy.find_by_id(id)
    if not buy:
        raise NotFoundRequest()
    buy.checkAuthorized()
    household_id = buy.household_id
    buy.delete()
    _emit_update(None, household_id)
    return jsonify({"msg": "DONE"})