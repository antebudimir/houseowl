"""drop recipe, planner and report recipe columns

Revision ID: c8d9e0a12b34
Revises: b7e2f4a91c03
Create Date: 2026-10-22 20:00:00.000000

"""
from alembic import op


# revision identifiers, used by Alembic.
revision = 'c8d9e0a12b34'
down_revision = 'b7e2f4a91c03'
branch_labels = None
depends_on = None


def upgrade():
    op.drop_table('planner')
    op.drop_table('recipe_history')
    op.drop_table('recipe_items')
    op.drop_table('recipe_tags')
    op.drop_table('recipe')
    op.drop_column('report', 'recipe_id')
    op.drop_column('household', 'planner_feature')


def downgrade():
    raise NotImplementedError()