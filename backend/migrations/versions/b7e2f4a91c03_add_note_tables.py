"""add note and note_tags tables

Revision ID: b7e2f4a91c03
Revises: a3f8c21d94e7
Create Date: 2026-10-22 20:10:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'b7e2f4a91c03'
down_revision = 'a3f8c21d94e7'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'note',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=128), nullable=False),
        sa.Column('body', sa.String(), nullable=False, server_default=''),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['household_id'], ['household.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        op.f('ix_note_household_id'), 'note', ['household_id'], unique=False
    )
    op.create_table(
        'note_tags',
        sa.Column('note_id', sa.Integer(), nullable=False),
        sa.Column('tag_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['note_id'], ['note.id']),
        sa.ForeignKeyConstraint(['tag_id'], ['tag.id']),
        sa.PrimaryKeyConstraint('note_id', 'tag_id'),
    )


def downgrade():
    op.drop_table('note_tags')
    op.drop_index(op.f('ix_note_household_id'), table_name='note')
    op.drop_table('note')
