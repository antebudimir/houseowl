"""add task and task_tags tables

Revision ID: e5b1c8d3f7a2
Revises: a7c3e91f40b2
Create Date: 2026-10-23 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'e5b1c8d3f7a2'
down_revision = 'a7c3e91f40b2'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'task',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=128), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('priority', sa.Integer(), nullable=False),
        sa.Column('recurrence', sa.String(length=16), nullable=False),
        sa.Column('due_date', sa.Date(), nullable=True),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('assignee_id', sa.Integer(), nullable=True),
        sa.Column('buy_id', sa.Integer(), nullable=True),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['assignee_id'], ['person.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['buy_id'], ['planned_buy.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['household_id'], ['household.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_task_household_id', 'task', ['household_id'])

    op.create_table(
        'task_tags',
        sa.Column('task_id', sa.Integer(), nullable=False),
        sa.Column('tag_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['task_id'], ['task.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['tag_id'], ['tag.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('task_id', 'tag_id'),
    )


def downgrade():
    op.drop_table('task_tags')
    op.drop_index('ix_task_household_id', table_name='task')
    op.drop_table('task')
