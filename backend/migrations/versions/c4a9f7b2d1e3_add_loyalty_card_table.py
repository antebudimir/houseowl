"""add loyalty_card table

Revision ID: c4a9f7b2d1e3
Revises: b2f8d5a6c9e1
Create Date: 2026-10-23 21:30:00.000000

"""
import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = 'c4a9f7b2d1e3'
down_revision = 'b2f8d5a6c9e1'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'loyalty_card',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('store_name', sa.String(length=255), nullable=False),
        sa.Column('card_number', sa.String(length=255), nullable=False),
        sa.Column('barcode_format', sa.String(length=32), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['household_id'], ['household.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_loyalty_card_household_id', 'loyalty_card', ['household_id'])


def downgrade():
    op.drop_index('ix_loyalty_card_household_id', table_name='loyalty_card')
    op.drop_table('loyalty_card')