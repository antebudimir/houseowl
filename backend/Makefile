# Smoke-test the head migration on a throwaway DB copy (upgrade + downgrade).
#
# NOTE: KITCHENOWL_DATABASE_URI is IGNORED by the config — it reads DB_NAME
# (a full path, default $STORAGE_PATH/database.db) and STORAGE_PATH. Setting
# the wrong variable silently points flask at the dev database.
smoke-migration:
	rm -rf /tmp/kowl-smoke && mkdir -p /tmp/kowl-smoke
	cp $(DB_SOURCE) /tmp/kowl-smoke/database.db
	DB_NAME=/tmp/kowl-smoke/database.db uv run flask db upgrade
	DB_NAME=/tmp/kowl-smoke/database.db uv run flask db downgrade e5b1c8d3f7a2
	rm -rf /tmp/kowl-smoke
