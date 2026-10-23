from datetime import date

from flask import Blueprint, jsonify, request
from flask_jwt_extended import current_user, jwt_required

from app import socketio
from app.errors import NotFoundRequest
from app.helpers import validate_args, authorize_household
from app.models import Person, PlannedBuy, Tag, Task, TaskTags
from .schemas import AddTask, UpdateTask

taskBP = Blueprint("task", __name__)
taskHousehold = Blueprint("task", __name__)


def _parse_due_date(raw):
    return date.fromisoformat(raw) if raw else None


def _set_assignee(task, household_id, assignee_id):
    if assignee_id is None:
        task.assignee_id = None
        return
    person = Person.find_by_id(assignee_id)
    if not person or person.household_id != household_id:
        raise NotFoundRequest()
    task.assignee_id = person.id


def _set_buy(task, household_id, buy_id):
    if buy_id is None:
        task.buy_id = None
        return
    buy = PlannedBuy.find_by_id(buy_id)
    if not buy or buy.household_id != household_id:
        raise NotFoundRequest()
    task.buy_id = buy.id


def _apply_tags(task, household_id, tag_names):
    for con in task.tags:
        if con.tag.name not in tag_names:
            con.delete()
    for tag_name in tag_names:
        tag = Tag.find_by_name(household_id, tag_name)
        if not tag:
            tag = Tag.create_by_name(household_id, tag_name)
        con = TaskTags.find_by_ids(task.id, tag.id)
        if not con:
            TaskTags(task=task, tag=tag).save()


def _emit_update(task_or_none, household_id):
    payload = (
        task_or_none.obj_to_full_dict() if task_or_none is not None else None
    )
    socketio.emit(
        "task:update",
        {"task": payload},
        to="household/" + str(household_id),
    )


@taskHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getTasks(household_id):
    tasks = Task.all_from_household(household_id)
    status = request.args.get("status")
    if status and status != "all":
        tasks = [t for t in tasks if t.status == status]
    if request.args.get("assignee") == "me":
        person = Person.query.filter(
            Person.household_id == household_id,
            Person.user_id == current_user.id,
        ).first()
        tasks = [t for t in tasks if t.assignee_id == person.id] if person else []
    tag_name = request.args.get("tag")
    if tag_name:
        tasks = [t for t in tasks if any(c.tag.name == tag_name for c in t.tags)]
    return jsonify([t.obj_to_full_dict() for t in tasks])


@taskHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddTask)
def addTask(args, household_id):
    task = Task()
    task.household_id = household_id
    task.name = args["name"]
    task.priority = args["priority"]
    task.recurrence = args["recurrence"]
    if args.get("description") is not None:
        task.description = args["description"]
    if args.get("due_date") is not None:
        task.due_date = _parse_due_date(args["due_date"])
    if args.get("assignee_id") is not None:
        _set_assignee(task, household_id, args["assignee_id"])
    if args.get("buy_id") is not None:
        _set_buy(task, household_id, args["buy_id"])
    task.save()
    if args.get("tags"):
        _apply_tags(task, household_id, args["tags"])
    _emit_update(task, household_id)
    return jsonify(task.obj_to_full_dict())


@taskBP.route("/<int:id>", methods=["GET"])
@jwt_required()
def getTask(id):
    task = Task.find_by_id(id)
    if not task:
        raise NotFoundRequest()
    task.checkAuthorized()
    return jsonify(task.obj_to_full_dict())


@taskBP.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateTask)
def updateTask(args, id):
    task = Task.find_by_id(id)
    if not task:
        raise NotFoundRequest()
    task.checkAuthorized()

    if "name" in args:
        task.name = args["name"]
    if "description" in args:
        task.description = args["description"]
    if "priority" in args:
        task.priority = args["priority"]
    if "recurrence" in args:
        task.recurrence = args["recurrence"]
    if "due_date" in args:
        task.due_date = _parse_due_date(args["due_date"])
    if "assignee_id" in args:
        _set_assignee(task, task.household_id, args["assignee_id"])
    if "buy_id" in args:
        _set_buy(task, task.household_id, args["buy_id"])
    if "tags" in args:
        _apply_tags(task, task.household_id, args["tags"])

    # Completion goes through the model: it stamps completed_at and, for
    # recurring tasks, materializes the next occurrence. Idempotent —
    # completing an already-done task clones nothing.
    successor = None
    if args.get("status") == "done" and task.completed_at is None:
        successor = task.complete()
    elif "status" in args:
        task.status = args["status"]
        # Reopening clears the completion stamp so a later re-complete
        # materializes again.
        if args["status"] == "open":
            task.completed_at = None

    task.save()
    _emit_update(task, task.household_id)
    if successor:
        _emit_update(successor, task.household_id)
    return jsonify(task.obj_to_full_dict())


@taskBP.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteTask(id):
    task = Task.find_by_id(id)
    if not task:
        raise NotFoundRequest()
    task.checkAuthorized()
    household_id = task.household_id
    task.delete()
    _emit_update(None, household_id)
    return jsonify({"msg": "DONE"})
