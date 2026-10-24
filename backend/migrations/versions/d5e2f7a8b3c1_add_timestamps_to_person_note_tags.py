"""Add created_at/updated_at timestamps to person, note and tag tables

DbModelBase gained the DbModelTimestampMixin (created_at/updated_at on every
model), but no migration was created for tables that already existed before
the mixin was introduced. This broke all person/note routes on databases
created from an older schema.

Also adds person.gift_idea, a dedicated gift idea field separate from
person.notes.

Revision ID: d5e2f7a8b3c1
Revises: c4a9f7b2d1e3
Create Date: 2026-10-24
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'd5e2f7a8b3c1'
down_revision = 'c4a9f7b2d1e3'
branch_labels = None
depends_on = None

TIMESTAMP_TABLES = [
    "person",
    "note",
    "note_tags",
    "task_tags",
    "event_attendee",
]


def upgrade():
    for table in TIMESTAMP_TABLES:
        with op.batch_alter_table(table) as batch_op:
            batch_op.add_column(
                sa.Column(
                    "created_at",
                    sa.DateTime(),
                    nullable=False,
                    server_default=sa.text("CURRENT_TIMESTAMP"),
                )
            )
            batch_op.add_column(
                sa.Column(
                    "updated_at",
                    sa.DateTime(),
                    nullable=False,
                    server_default=sa.text("CURRENT_TIMESTAMP"),
                )
            )

    with op.batch_alter_table("person") as batch_op:
        batch_op.add_column(sa.Column("gift_idea", sa.String(), nullable=True))


def downgrade():
    with op.batch_alter_table("person") as batch_op:
        batch_op.drop_column("gift_idea")

    for table in TIMESTAMP_TABLES:
        with op.batch_alter_table(table) as batch_op:
            batch_op.drop_column("updated_at")
            batch_op.drop_column("created_at")