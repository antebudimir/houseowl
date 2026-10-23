"""add hidden_views to household

Revision ID: b8e4f2a7c9d1
Revises: f9d2a4b6c1e8
Create Date: 2026-10-23 20:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
import app.helpers.db_list_type


# revision identifiers, used by Alembic.
revision = 'b8e4f2a7c9d1'
down_revision = 'f9d2a4b6c1e8'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('household', schema=None) as batch_op:
        batch_op.add_column(sa.Column('hidden_views', app.helpers.db_list_type.DbListType(), nullable=True))


def downgrade():
    with op.batch_alter_table('household', schema=None) as batch_op:
        batch_op.drop_column('hidden_views')