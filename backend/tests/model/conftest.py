import os

os.environ["KITCHENOWL_MCP_ENABLED"] = "true"

import pytest
from sqlalchemy import event

from app import app, db

# SQLite does not enforce foreign keys (ON DELETE SET NULL / CASCADE) unless
# the pragma is enabled per connection. Production databases do. Registered
# at import time so every pooled connection gets it, in any test order.
with app.app_context():

    @event.listens_for(db.engine, "connect")
    def _enable_sqlite_fk(dbapi_conn, _record):
        dbapi_conn.execute("PRAGMA foreign_keys=ON")


@pytest.fixture
def db_session():
    app_context = app.app_context()
    app_context.push()
    app.config["TESTING"] = True

    db.create_all()
    yield db.session
    db.session.rollback()
    db.drop_all()
    app_context.pop()
