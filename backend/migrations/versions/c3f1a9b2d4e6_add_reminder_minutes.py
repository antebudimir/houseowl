"""Add reminder_minutes to event and task

Stores an optional reminder lead time in minutes, counted back from the
event start / task due date. NULL means "no reminder". Delivery is handled
client-side by scheduling a local notification, so no extra table is needed.

Revision ID: c3f1a9b2d4e6
Revises: b8e4f2a1c7d9
Create Date: 2026-11-13
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'c3f1a9b2d4e6'
down_revision = 'b8e4f2a1c7d9'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('event', recreate='always') as batch_op:
        batch_op.add_column(
            sa.Column('reminder_minutes', sa.Integer(), nullable=True)
        )
    with op.batch_alter_table('task', recreate='always') as batch_op:
        batch_op.add_column(
            sa.Column('reminder_minutes', sa.Integer(), nullable=True)
        )


def downgrade():
    with op.batch_alter_table('task', recreate='always') as batch_op:
        batch_op.drop_column('reminder_minutes')
    with op.batch_alter_table('event', recreate='always') as batch_op:
        batch_op.drop_column('reminder_minutes')
