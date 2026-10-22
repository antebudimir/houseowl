"""add planned buys; remove expense system

Revision ID: a7c3e91f40b2
Revises: c8d9e0a12b34
Create Date: 2026-10-22 22:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a7c3e91f40b2'
down_revision = 'c8d9e0a12b34'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'planned_buy',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=128), nullable=False),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('priority', sa.Integer(), nullable=False),
        sa.Column('category', sa.String(length=128), nullable=True),
        sa.Column('target_date', sa.DateTime(), nullable=True),
        sa.Column('actual_price', sa.Float(), nullable=True),
        sa.Column('acquired_at', sa.DateTime(), nullable=True),
        sa.Column('assignee_id', sa.Integer(), nullable=True),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['assignee_id'], ['person.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['household_id'], ['household.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_planned_buy_household_id', 'planned_buy', ['household_id'])

    # child first, then parents
    op.drop_table('expense_paid_for')
    op.drop_table('expense')
    op.drop_table('expense_category')

    with op.batch_alter_table('household_member') as batch_op:
        batch_op.drop_column('expense_balance')
    with op.batch_alter_table('household') as batch_op:
        batch_op.drop_column('expenses_feature')


def downgrade():
    raise NotImplementedError()