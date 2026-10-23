"""add document table

Revision ID: b2f8d5a6c9e1
Revises: b8e4f2a7c9d1
Create Date: 2026-10-23 19:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'b2f8d5a6c9e1'
down_revision = 'b8e4f2a7c9d1'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'document',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('file_id', sa.String(), nullable=True),
        sa.Column('contact_id', sa.Integer(), nullable=True),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['contact_id'], ['person.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['file_id'], ['file.filename']),
        sa.ForeignKeyConstraint(['household_id'], ['household.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_document_household_id', 'document', ['household_id'])
    op.create_index('ix_document_expires_at', 'document', ['expires_at'])


def downgrade():
    op.drop_index('ix_document_expires_at', table_name='document')
    op.drop_index('ix_document_household_id', table_name='document')
    op.drop_table('document')
