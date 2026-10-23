from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required

from app import socketio
from app.errors import NotFoundRequest
from app.helpers import authorize_household, validate_args
from app.models import BARCODE_FORMATS, LoyaltyCard

from .schemas import AddLoyaltyCard, GetLoyaltyCards, UpdateLoyaltyCard

loyaltyCard = Blueprint("loyaltyCard", __name__)
loyaltyCardHousehold = Blueprint("loyaltyCardHousehold", __name__)


@loyaltyCardHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(GetLoyaltyCards)
def getLoyaltyCards(args, household_id):
    if args.get("search"):
        return jsonify(
            [
                c.obj_to_full_dict()
                for c in LoyaltyCard.search(household_id, args["search"])
            ]
        )
    return jsonify(
        [c.obj_to_full_dict() for c in LoyaltyCard.all_from_household(household_id)]
    )


@loyaltyCardHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddLoyaltyCard)
def addLoyaltyCard(args, household_id):
    card = LoyaltyCard()
    card.store_name = args["store_name"]
    card.card_number = args["card_number"]
    card.barcode_format = args["barcode_format"]
    card.household_id = household_id
    card.notes = args.get("notes")
    card.save()
    socketio.emit(
        "loyalty_card:update",
        {"loyalty_card": card.obj_to_full_dict()},
        to="household/" + str(household_id),
    )
    return jsonify(card.obj_to_full_dict())


@loyaltyCard.route("/formats", methods=["GET"])
@jwt_required()
def getBarcodeFormats():
    # The authoritative whitelist, mirrored by the client's
    # `barcode_formats.dart` enum (a client test keeps the two in sync).
    return jsonify(sorted(BARCODE_FORMATS))


@loyaltyCard.route("/<int:id>", methods=["GET"])
@jwt_required()
def getLoyaltyCardById(id):
    card = LoyaltyCard.find_by_id(id)
    if not card:
        raise NotFoundRequest()
    card.checkAuthorized()
    return jsonify(card.obj_to_full_dict())


@loyaltyCard.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateLoyaltyCard)
def updateLoyaltyCard(args, id):
    card = LoyaltyCard.find_by_id(id)
    if not card:
        raise NotFoundRequest()
    card.checkAuthorized()

    if "store_name" in args:
        card.store_name = args["store_name"]
    if "card_number" in args:
        card.card_number = args["card_number"]
    if "barcode_format" in args:
        card.barcode_format = args["barcode_format"]
    if "notes" in args:
        card.notes = args["notes"]
    card.save()
    socketio.emit(
        "loyalty_card:update",
        {"loyalty_card": card.obj_to_full_dict()},
        to="household/" + str(card.household_id),
    )
    return jsonify(card.obj_to_full_dict())


@loyaltyCard.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteLoyaltyCard(id):
    card = LoyaltyCard.find_by_id(id)
    if not card:
        raise NotFoundRequest()
    card.checkAuthorized()
    household_id = card.household_id
    card.delete()
    socketio.emit(
        "loyalty_card:update",
        {"loyalty_card": None},
        to="household/" + str(household_id),
    )
    return jsonify({"msg": "DONE"})
