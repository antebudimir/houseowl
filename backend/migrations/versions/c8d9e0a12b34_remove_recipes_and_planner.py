"""drop recipe, planner and report recipe columns

Revision ID: c8d9e0a12b34
Revises: b7e2f4a91c03
Create Date: 2026-10-22 20:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


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
    # SQLite cannot drop a column that participates in a foreign key
    # definition, and reflecting the table would try to resolve its FK to
    # the just-dropped recipe table. Recreate explicitly instead.
    op.rename_table('report', 'report_old')
    op.create_table(
        'report',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('description', sa.String(), nullable=True),
        sa.Column('created_by_id', sa.Integer(), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ['created_by_id'], ['user.id'], name=op.f('fk_report_created_by_id_user')
        ),
        sa.ForeignKeyConstraint(
            ['user_id'], ['user.id'], name=op.f('fk_report_user_id_user')
        ),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_report')),
    )
    op.execute(
        f"INSERT INTO report (id, description, created_by_id, user_id, "
        f"created_at, updated_at) SELECT id, description, created_by_id, "
        f"user_id, created_at, updated_at FROM report_old"
    )
    op.drop_table('report_old')
    op.drop_column('household', 'planner_feature')


def downgrade():
    raise NotImplementedError()