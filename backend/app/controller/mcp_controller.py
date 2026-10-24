from __future__ import annotations

import json
import uuid
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime, timezone
from queue import Empty, Queue
from typing import Any

from flask import Blueprint, Response, jsonify, request, url_for
from flask_jwt_extended import current_user, jwt_required

from app import db
from app.config import BACKEND_VERSION
from app.errors import NotFoundRequest
from app.models import (
    BARCODE_FORMATS,
    Document,
    Event,
    EventAttendee,
    History,
    LoyaltyCard,
    Task,
    Household,
    HouseholdMember,
    Item,
    Person,
    Shoppinglist,
    ShoppinglistItems,
    Tag,
)

mcp = Blueprint("mcp", __name__)


def _as_tool_result(payload: Any):
    text = json.dumps(payload, ensure_ascii=False, default=str)
    return {
        "content": [{"type": "text", "text": text}],
        "structuredContent": payload,
    }


def _require_household_access(household_id: int):
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    if not member:
        raise NotFoundRequest()


def _tool_list_households(_args: dict[str, Any]) -> Any:
    members = HouseholdMember.find_by_user(current_user.id)
    return {"items": [m.household.obj_to_dict() for m in members]}


def _tool_list_shoppinglists(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    return {"items": [e.obj_to_dict() for e in Shoppinglist.all_from_household(household_id)]}


def _tool_list_shoppinglist_items(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()
    items = (
        ShoppinglistItems.query.filter(ShoppinglistItems.shoppinglist_id == list_id)
        .join(ShoppinglistItems.item)
        .all()
    )
    return {"items": [e.obj_to_item_dict() for e in items]}


def _tool_add_item_by_name(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    name = str(args["name"]).strip()
    description = str(args.get("description", ""))

    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    item = Item.find_by_name(shoppinglist.household_id, name)
    if not item:
        item = Item.create_by_name(shoppinglist.household_id, name)

    con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
    if not con:
        con = ShoppinglistItems(description=description)
        con.created_by = current_user.id
        con.item = item
        con.shoppinglist = shoppinglist
        con.save()
        History.create_added(shoppinglist, item, description)

    return item.obj_to_dict()


def _tool_list_items(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    search = str(args.get("search", "")).strip()

    q = Item.query.filter(Item.household_id == household_id)
    if search:
        q = q.filter(Item.name.ilike(f"%{search}%"))
    items = q.order_by(Item.name).limit(100).all()
    return {"items": [i.obj_to_dict() for i in items]}


def _tool_list_tags(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    tags = Tag.query.filter(Tag.household_id == household_id).order_by(Tag.name).all()
    return {"items": [t.obj_to_full_dict() for t in tags]}


def _tool_create_tag(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    name = str(args["name"]).strip()
    if not name:
        return {"created": False, "reason": "empty_name"}

    tag = Tag.find_by_name(household_id, name)
    if not tag:
        tag = Tag.create_by_name(household_id, name)
    return tag.obj_to_full_dict()


def _tool_list_tasks(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    status = str(args.get("status", "open"))
    tasks = Task.all_from_household(household_id)
    if status != "all":
        tasks = [t for t in tasks if t.status == status]
    return {"items": [t.obj_to_full_dict() for t in tasks]}


def _tool_create_task(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    name = str(args["name"]).strip()
    if not name:
        return {"created": False, "reason": "empty_name"}

    task = Task()
    task.household_id = household_id
    task.name = name
    if args.get("due_date"):
        from datetime import date

        task.due_date = date.fromisoformat(str(args["due_date"]))
    if args.get("recurrence"):
        task.recurrence = str(args["recurrence"])
    task.save()
    if args.get("tags"):
        from app.models import TaskTags, Tag

        for tag_name in args["tags"]:
            tag = Tag.find_by_name(household_id, str(tag_name))
            if not tag:
                tag = Tag.create_by_name(household_id, str(tag_name))
            TaskTags(task=task, tag=tag).save()
    return task.obj_to_full_dict()


def _tool_complete_task(args: dict[str, Any]) -> Any:
    task = Task.find_by_id(int(args["task_id"]))
    if not task:
        raise NotFoundRequest()
    task.checkAuthorized()
    successor = task.complete()
    res = {"task": task.obj_to_full_dict()}
    if successor:
        res["next_occurrence"] = successor.obj_to_full_dict()
    return res


def _tool_delete_task(args: dict[str, Any]) -> Any:
    task = Task.find_by_id(int(args["task_id"]))
    if not task:
        raise NotFoundRequest()
    task.checkAuthorized()
    task.delete()
    return {"deleted": True}


def _tool_list_documents(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    expiring_within = args.get("expiring_within")
    if expiring_within is not None:
        return {
            "items": [
                d.obj_to_full_dict()
                for d in Document.find_expiring(household_id, int(expiring_within))
            ]
        }
    return {
        "items": [d.obj_to_full_dict() for d in Document.all_from_household(household_id)]
    }


def _tool_create_document(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    title = str(args["title"]).strip()
    if not title:
        return {"created": False, "reason": "empty_title"}

    document = Document()
    document.household_id = household_id
    document.title = title
    if args.get("notes"):
        document.notes = str(args["notes"])
    if args.get("expires_at") is not None:
        document.expires_at = datetime.fromtimestamp(
            int(args["expires_at"]) / 1000, timezone.utc
        )
    if args.get("contact_id"):
        person = Person.find_by_id(int(args["contact_id"]))
        if not person or person.household_id != household_id:
            return {"created": False, "reason": "invalid_contact"}
        document.contact = person
    document.save()
    return document.obj_to_full_dict()


def _tool_list_loyalty_cards(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    return {
        "items": [
            c.obj_to_full_dict()
            for c in LoyaltyCard.all_from_household(household_id)
        ]
    }


def _tool_create_loyalty_card(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    store_name = str(args["store_name"]).strip()
    card_number = str(args["card_number"]).strip()
    barcode_format = str(args["barcode_format"]).strip()
    if not store_name:
        return {"created": False, "reason": "empty_store_name"}
    if not card_number:
        return {"created": False, "reason": "empty_card_number"}
    if barcode_format not in BARCODE_FORMATS:
        return {"created": False, "reason": "invalid_barcode_format"}

    card = LoyaltyCard()
    card.household_id = household_id
    card.store_name = store_name
    card.card_number = card_number
    card.barcode_format = barcode_format
    if args.get("notes"):
        card.notes = str(args["notes"])
    card.save()
    return card.obj_to_full_dict()


def _tool_delete_loyalty_card(args: dict[str, Any]) -> Any:
    card = LoyaltyCard.find_by_id(int(args["loyalty_card_id"]))
    if not card:
        raise NotFoundRequest()
    card.checkAuthorized()
    card.delete()
    return {"deleted": True}


def _tool_list_events(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    return {"items": [e.obj_to_full_dict() for e in Event.all_from_household(household_id)]}


def _tool_create_event(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    name = str(args["name"]).strip()
    if not name:
        return {"created": False, "reason": "empty_name"}

    from datetime import datetime, timezone

    start = datetime.fromtimestamp(int(args["start"]) / 1000, timezone.utc)
    end = datetime.fromtimestamp(int(args["end"]) / 1000, timezone.utc)
    if end <= start:
        return {"created": False, "reason": "end_not_after_start"}

    attendee_ids = [int(a) for a in args.get("attendees", [])]
    conflicts = Event.find_conflicts(household_id, start, end, attendee_ids)
    if conflicts:
        return {
            "created": False,
            "reason": "conflict",
            "conflicts": [c.obj_to_full_dict() for c in conflicts],
        }

    event = Event()
    event.household_id = household_id
    event.name = name
    event.start = start
    event.end = end
    event.all_day = bool(args.get("all_day", False))
    if args.get("description"):
        event.description = str(args["description"])
    if args.get("location"):
        event.location = str(args["location"])
    event.save()
    for person_id in attendee_ids:
        person = Person.find_by_id(person_id)
        if person and person.household_id == household_id:
            EventAttendee(event=event, person=person).save()
    return event.obj_to_full_dict()


def _tool_delete_event(args: dict[str, Any]) -> Any:
    event = Event.find_by_id(int(args["event_id"]))
    if not event:
        raise NotFoundRequest()
    event.checkAuthorized()
    event.delete()
    return {"deleted": True}


def _tool_create_shoppinglist(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    name = str(args["name"]).strip()[:128]
    if not name:
        return {"created": False, "reason": "empty_name"}

    shoppinglist = Shoppinglist(name=name, household_id=household_id)
    shoppinglist.save()
    return shoppinglist.obj_to_dict()


def _tool_delete_shoppinglist(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    if shoppinglist.isDefault():
        return {"deleted": False, "reason": "default_list"}

    name = shoppinglist.name
    shoppinglist.delete()
    return {"deleted": True, "id": list_id, "name": name}


def _tool_remove_item_from_list(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    item_id = args.get("item_id")
    item_name = str(args.get("name", "")).strip()

    con = None
    if item_id is not None:
        con = ShoppinglistItems.find_by_ids(list_id, int(item_id))
    elif item_name:
        item = Item.find_by_name(shoppinglist.household_id, item_name)
        if item:
            con = ShoppinglistItems.find_by_ids(list_id, item.id)

    if not con:
        return {"removed": False, "reason": "not_found"}

    removed_item = con.item.obj_to_dict()
    con.delete()
    return {"removed": True, "list_id": list_id, "item": removed_item}


TOOLS: dict[str, tuple[dict[str, Any], Callable[[dict[str, Any]], Any]]] = {
    "list_households": (
        {"type": "object", "properties": {}},
        _tool_list_households,
    ),
    "list_shoppinglists": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_shoppinglists,
    ),
    "list_shoppinglist_items": (
        {
            "type": "object",
            "properties": {"list_id": {"type": "integer"}},
            "required": ["list_id"],
        },
        _tool_list_shoppinglist_items,
    ),
    "add_item_by_name": (
        {
            "type": "object",
            "properties": {
                "list_id": {"type": "integer"},
                "name": {"type": "string"},
                "description": {"type": "string"},
            },
            "required": ["list_id", "name"],
        },
        _tool_add_item_by_name,
    ),
    "list_items": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "search": {"type": "string"},
            },
            "required": ["household_id"],
        },
        _tool_list_items,
    ),
    "list_tags": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_tags,
    ),
    "create_tag": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["household_id", "name"],
        },
        _tool_create_tag,
    ),
    "create_shoppinglist": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["household_id", "name"],
        },
        _tool_create_shoppinglist,
    ),
    "delete_shoppinglist": (
        {
            "type": "object",
            "properties": {"list_id": {"type": "integer"}},
            "required": ["list_id"],
        },
        _tool_delete_shoppinglist,
    ),
    "remove_item_from_list": (
        {
            "type": "object",
            "properties": {
                "list_id": {"type": "integer"},
                "item_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["list_id"],
        },
        _tool_remove_item_from_list,
    ),
    "list_tasks": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "status": {"type": "string", "enum": ["open", "done", "all"]},
            },
            "required": ["household_id"],
        },
        _tool_list_tasks,
    ),
    "create_task": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
                "due_date": {"type": "string", "description": "ISO date YYYY-MM-DD"},
                "recurrence": {
                    "type": "string",
                    "enum": ["none", "daily", "weekly", "biweekly", "monthly", "yearly"],
                },
                "tags": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["household_id", "name"],
        },
        _tool_create_task,
    ),
    "complete_task": (
        {
            "type": "object",
            "properties": {"task_id": {"type": "integer"}},
            "required": ["task_id"],
        },
        _tool_complete_task,
    ),
    "delete_task": (
        {
            "type": "object",
            "properties": {"task_id": {"type": "integer"}},
            "required": ["task_id"],
        },
        _tool_delete_task,
    ),
    "list_events": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_events,
    ),
    "create_event": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
                "start": {
                    "type": "integer",
                    "description": "UTC epoch milliseconds",
                },
                "end": {
                    "type": "integer",
                    "description": "UTC epoch milliseconds, must be after start",
                },
                "all_day": {"type": "boolean"},
                "description": {"type": "string"},
                "location": {"type": "string"},
                "attendees": {
                    "type": "array",
                    "items": {"type": "integer"},
                    "description": "Person ids; conflicting attendees block creation",
                },
            },
            "required": ["household_id", "name", "start", "end"],
        },
        _tool_create_event,
    ),
    "delete_event": (
        {
            "type": "object",
            "properties": {"event_id": {"type": "integer"}},
            "required": ["event_id"],
        },
        _tool_delete_event,
    ),
    "list_documents": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "expiring_within": {
                    "type": "integer",
                    "description": "Only documents whose expires_at is within this many days (includes already-expired)",
                },
            },
            "required": ["household_id"],
        },
        _tool_list_documents,
    ),
    "create_document": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "title": {"type": "string"},
                "notes": {"type": "string"},
                "expires_at": {
                    "type": "integer",
                    "description": "UTC epoch milliseconds",
                },
                "contact_id": {"type": "integer"},
            },
            "required": ["household_id", "title"],
        },
        _tool_create_document,
    ),
    "list_loyalty_cards": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_loyalty_cards,
    ),
    "create_loyalty_card": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "store_name": {"type": "string"},
                "card_number": {"type": "string"},
                "barcode_format": {
                    "type": "string",
                    "description": "One of: "
                    + ", ".join(sorted(BARCODE_FORMATS)),
                },
                "notes": {"type": "string"},
            },
            "required": ["household_id", "store_name", "card_number", "barcode_format"],
        },
        _tool_create_loyalty_card,
    ),
    "delete_loyalty_card": (
        {
            "type": "object",
            "properties": {"loyalty_card_id": {"type": "integer"}},
            "required": ["loyalty_card_id"],
        },
        _tool_delete_loyalty_card,
    ),
}



SUPPORTED_PROTOCOL_VERSIONS = ("2025-06-18", "2025-03-26", "2024-11-05")
LATEST_PROTOCOL_VERSION = SUPPORTED_PROTOCOL_VERSIONS[0]

SERVER_INSTRUCTIONS = (
    "HouseOwl manages households, each of which owns shopping lists, items, "
    "tags, tasks and events. Nearly every tool is scoped to a "
    "household, so call list_households first and reuse the id you get back."
)

SSE_KEEPALIVE_SECONDS = 15


def _dispatch(body: Any) -> Any:
    # Returns the response to send back, or None for notifications, which the
    # protocol requires be left unanswered.
    if isinstance(body, list):
        responses = [r for r in (_dispatch(item) for item in body) if r is not None]
        return responses or None

    if not isinstance(body, dict):
        return {
            "jsonrpc": "2.0",
            "id": None,
            "error": {"code": -32600, "message": "Invalid Request"},
        }

    id_value = body.get("id")
    method = body.get("method")
    params = body.get("params") or {}
    is_notification = "id" not in body

    try:
        if method == "initialize":
            requested = params.get("protocolVersion")
            version = (
                requested
                if requested in SUPPORTED_PROTOCOL_VERSIONS
                else LATEST_PROTOCOL_VERSION
            )
            result = {
                "protocolVersion": version,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {
                    "name": "houseowl-mcp",
                    "version": str(BACKEND_VERSION),
                },
                "instructions": SERVER_INSTRUCTIONS,
            }
        elif method is not None and method.startswith("notifications/"):
            return None
        elif method == "ping":
            result = {}
        elif method == "tools/list":
            result = {
                "tools": [
                    {
                        "name": name,
                        "description": f"HouseOwl tool: {name}",
                        "inputSchema": schema,
                    }
                    for name, (schema, _) in TOOLS.items()
                ]
            }
        elif method == "tools/call":
            name = params.get("name")
            args = params.get("arguments") or {}
            if name not in TOOLS:
                return None if is_notification else _rpc_error(
                    id_value, -32602, f"Unknown tool: {name}"
                )
            _, handler = TOOLS[name]
            result = _as_tool_result(handler(args))
            db.session.commit()
        else:
            return None if is_notification else _rpc_error(
                id_value, -32601, f"Method not found: {method}"
            )
    except Exception as e:
        db.session.rollback()
        return None if is_notification else _rpc_error(id_value, -32000, str(e))

    return None if is_notification else {"jsonrpc": "2.0", "id": id_value, "result": result}


def _rpc_error(id_value: Any, code: int, message: str) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": id_value, "error": {"code": code, "message": message}}


# Streamable HTTP. Stateless: no session id is issued, so this transport keeps
# working across multiple uWSGI workers.


@mcp.route("", methods=["POST"])
@jwt_required()
def mcp_post():
    response = _dispatch(request.get_json(silent=True))
    if response is None:
        return "", 202
    return jsonify(response)


@mcp.route("", methods=["GET", "DELETE"])
@jwt_required()
def mcp_stream_unsupported():
    # Nothing to push outside a request and no session to tear down; the spec
    # allows 405 for both.
    return Response(status=405, headers={"Allow": "POST"})


# HTTP+SSE. Both halves of a session must be served by the same process, so this
# registry is deliberately per-worker.


@dataclass
class _SseSession:
    user_id: int
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    outbox: Queue = field(default_factory=Queue)


_sse_sessions: dict[str, _SseSession] = {}


@mcp.route("/sse", methods=["GET"])
@jwt_required()
def mcp_sse():
    session = _SseSession(user_id=current_user.id)
    _sse_sessions[session.id] = session

    # Relative, so it survives a reverse proxy that request.url_root would not.
    endpoint = f"{url_for('mcp.mcp_messages')}?session_id={session.id}"

    def generate():
        try:
            yield f"event: endpoint\ndata: {endpoint}\n\n"
            while True:
                try:
                    message = session.outbox.get(timeout=SSE_KEEPALIVE_SECONDS)
                except Empty:
                    yield ": keep-alive\n\n"
                    continue
                yield "event: message\ndata: {}\n\n".format(
                    json.dumps(message, ensure_ascii=False, default=str)
                )
        finally:
            _sse_sessions.pop(session.id, None)

    return Response(
        generate(),
        mimetype="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@mcp.route("/messages", methods=["POST"])
@mcp.route("/messages/<session_id>", methods=["POST"])
@jwt_required()
def mcp_messages(session_id: str | None = None):
    session_id = session_id or request.args.get("session_id")
    session = _sse_sessions.get(session_id) if session_id else None

    if session is None:
        return jsonify({"error": "Unknown or expired session"}), 404
    if session.user_id != current_user.id:
        return jsonify({"error": "Session belongs to a different user"}), 403

    response = _dispatch(request.get_json(silent=True))
    if response is not None:
        session.outbox.put(response)

    # The reply travels over the SSE stream, not this response.
    return "", 202
