import time
from app.config import app
from app.models import Household
from app.service.importServices import (
    importItem,
    importShoppinglist,
)
from .schemas import ImportSchema
from app.helpers import validate_args, authorize_household
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required

importBP = Blueprint("import", __name__)


@importBP.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(ImportSchema)
def importData(args, household_id):
    household = Household.find_by_id(household_id)
    if not household:
        return

    app.logger.info("Starting import...")

    t0 = time.time()
    if "items" in args:
        for item in args["items"]:
            importItem(household, item)

    if "shoppinglists" in args:
        for shoppinglist in args["shoppinglists"]:
            importShoppinglist(household, shoppinglist)

    app.logger.info(f"Import took: {(time.time() - t0):.3f}s")
    return jsonify({"msg": "DONE"})
