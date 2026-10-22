"""add person table

Revision ID: a3f8c21d94e7
Revises: 0b10d67750be
Create Date: 2026-10-22 18:40:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a3f8c21d94e7'
down_revision = '0b10d67750be'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'person',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=128), nullable=False),
        sa.Column('role', sa.String(length=128), nullable=True),
        sa.Column('phone', sa.String(length=64), nullable=True),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('notes', sa.String(), nullable=True),
        sa.Column('birthday', sa.Date(), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['household_id'], ['household.id']),
        sa.ForeignKeyConstraint(['user_id'], ['user.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        op.f('ix_person_household_id'), 'person', ['household_id'], unique=False
    )


def downgrade():
    op.drop_index(op.f('ix_person_household_id'), table_name='person')
    op.drop_table('person')