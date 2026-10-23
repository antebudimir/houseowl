from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.errors import NotFoundRequest
from app.helpers import authorize_household
from app.models import Document, Household, Item

export = Blueprint("export", __name__)


@export.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getExportAll(household_id):
    household = Household.find_by_id(household_id)
    if not household:
        raise NotFoundRequest()

    return household.obj_to_export_dict()


@export.route("/items", methods=["GET"])
@jwt_required()
@authorize_household()
def getExportItems(household_id):
    return jsonify(
        {
            "items": [
                e.obj_to_export_dict()
                for e in Item.all_from_household_by_name(household_id)
            ]
        }
    )


@export.route("/documents", methods=["GET"])
@jwt_required()
@authorize_household()
def getExportDocuments(household_id):
    household = Household.find_by_id(household_id)
    if not household:
        raise NotFoundRequest()

    return jsonify(
        {
            "documents": [
                d.obj_to_export_dict()
                for d in Document.all_from_household(household_id)
            ]
        }
    )
