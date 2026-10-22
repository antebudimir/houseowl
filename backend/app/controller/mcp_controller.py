from __future__ import annotations

import json
import uuid
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime
from queue import Empty, Queue
from typing import Any

from flask import Blueprint, Response, jsonify, request, url_for
from flask_jwt_extended import current_user, jwt_required

from app import db
from app.config import BACKEND_VERSION
from app.errors import NotFoundRequest
from app.models import (
    Expense,
    File,
    History,
    Household,
    HouseholdMember,
    Item,
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


def _tool_list_expenses(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    search = str(args.get("search", "")).strip()
    _require_household_access(household_id)

    q = Expense.query.filter(Expense.household_id == household_id)
    if search:
        q = q.filter(Expense.name.ilike(f"%{search}%"))
    expenses = q.order_by(Expense.date.desc()).limit(50).all()
    return {"items": [e.obj_to_full_dict() for e in expenses]}


def _tool_create_expense(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)

    expense = Expense()
    expense.household_id = household_id
    expense.name = str(args["name"]).strip()[:128]
    expense.amount = float(args["amount"])
    expense.description = str(args.get("description", ""))
    expense.paid_by_id = current_user.id

    date_raw = args.get("date")
    if date_raw:
        expense.date = datetime.fromisoformat(str(date_raw).replace("Z", "+00:00"))

    expense.save()
    return expense.obj_to_full_dict()


def _tool_delete_expense(args: dict[str, Any]) -> Any:
    expense_id = int(args["expense_id"])
    expense = Expense.find_by_id(expense_id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()
    name = expense.name
    expense.delete()
    return {"deleted": True, "id": expense_id, "name": name}


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
    "list_expenses": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "search": {"type": "string"},
            },
            "required": ["household_id"],
        },
        _tool_list_expenses,
    ),
    "create_expense": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
                "amount": {"type": "number"},
                "description": {"type": "string"},
                "date": {"type": "string"},
            },
            "required": ["household_id", "name", "amount"],
        },
        _tool_create_expense,
    ),
    "delete_expense": (
        {
            "type": "object",
            "properties": {"expense_id": {"type": "integer"}},
            "required": ["expense_id"],
        },
        _tool_delete_expense,
    ),
}



SUPPORTED_PROTOCOL_VERSIONS = ("2025-06-18", "2025-03-26", "2024-11-05")
LATEST_PROTOCOL_VERSION = SUPPORTED_PROTOCOL_VERSIONS[0]

SERVER_INSTRUCTIONS = (
    "KitchenOwl manages households, each of which owns shopping lists, items, "
    "tags, notes and expenses. Nearly every tool is scoped to a "
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
                    "name": "kitchenowl-mcp",
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
                        "description": f"KitchenOwl tool: {name}",
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
