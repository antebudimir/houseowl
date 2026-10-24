import os
import tempfile

os.environ["HOUSEOWL_MCP_ENABLED"] = "true"
# Isolate pytest from the developer database: app config reads DB_NAME at
# import time, so point it at a throwaway file before importing the app.
# Test fixtures end with db.drop_all(), which would wipe a shared DB.
# This runs when the tests package is imported, before any conftest or test
# module can import the app.
if "DB_NAME" not in os.environ:
    _TEST_DB_DIR = tempfile.mkdtemp(prefix="kowl-pytest-")
    os.environ["DB_NAME"] = os.path.join(_TEST_DB_DIR, "test.db")

    import atexit

    def _cleanup_test_db():
        for suffix in ("", "-wal", "-shm"):
            try:
                os.remove(os.environ["DB_NAME"] + suffix)
            except FileNotFoundError:
                pass

    atexit.register(_cleanup_test_db)

import app
