"""Repoint event attendees, assignees and document owner to household members

Attendee/assignee/owner references moved from person.id to household member
user.id (models changed in the same release). On SQLite every column FK
change requires a table rebuild, hence batch operations throughout.

Existing rows are preserved: the old person-based values are backfilled
through person.user_id (rows whose person has no linked user become NULL
for the nullable columns and are dropped for attendees).

Revision ID: b8e4f2a1c7d9
Revises: d5e2f7a8b3c1
Create Date: 2026-10-26
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'b8e4f2a1c7d9'
down_revision = 'd5e2f7a8b3c1'
branch_labels = None
depends_on = None


def upgrade():
    # event_attendee: PK changes from (event_id, person_id) to
    # (event_id, user_id), so the table is rebuilt with a data-preserving
    # copy. Rows whose person has no linked user cannot be kept.
    op.create_table(
        'event_attendee_new',
        sa.Column('event_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column(
            'created_at',
            sa.DateTime(),
            nullable=False,
            server_default=sa.text('CURRENT_TIMESTAMP'),
        ),
        sa.Column(
            'updated_at',
            sa.DateTime(),
            nullable=False,
            server_default=sa.text('CURRENT_TIMESTAMP'),
        ),
        sa.ForeignKeyConstraint(['event_id'], ['event.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['user.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('event_id', 'user_id'),
    )
    op.execute(
        'INSERT INTO event_attendee_new (event_id, user_id, created_at, updated_at) '
        'SELECT ea.event_id, p.user_id, ea.created_at, ea.updated_at '
        'FROM event_attendee ea JOIN person p ON p.id = ea.person_id '
        'WHERE p.user_id IS NOT NULL'
    )
    op.drop_table('event_attendee')
    op.rename_table('event_attendee_new', 'event_attendee')

    # document.contact_id -> owner_id (nullable, SET NULL)
    with op.batch_alter_table('document', recreate='always') as batch_op:
        batch_op.add_column(
            sa.Column(
                'owner_id',
                sa.Integer(),
                sa.ForeignKey('user.id', ondelete='SET NULL'),
                nullable=True,
            )
        )
    op.execute(
        'UPDATE document SET owner_id = '
        '(SELECT user_id FROM person WHERE person.id = document.contact_id) '
        'WHERE contact_id IS NOT NULL'
    )
    with op.batch_alter_table('document', recreate='always') as batch_op:
        batch_op.drop_column('contact_id')

    # task.assignee_id / planned_buy.assignee_id: repoint person.id -> user.id
    for table in ('task', 'planned_buy'):
        with op.batch_alter_table(table, recreate='always') as batch_op:
            batch_op.add_column(
                sa.Column(
                    'user_assignee_id',
                    sa.Integer(),
                    sa.ForeignKey('user.id', ondelete='SET NULL'),
                    nullable=True,
                )
            )
        op.execute(
            f'UPDATE {table} SET user_assignee_id = '
            '(SELECT user_id FROM person WHERE person.id = '
            f'{table}.assignee_id) WHERE assignee_id IS NOT NULL'
        )
        with op.batch_alter_table(table, recreate='always') as batch_op:
            batch_op.drop_column('assignee_id')
        with op.batch_alter_table(table, recreate='always') as batch_op:
            batch_op.alter_column(
                'user_assignee_id',
                new_column_name='assignee_id',
                existing_type=sa.Integer(),
                existing_nullable=True,
            )


def downgrade():
    # Reverse shape only: rows are not mapped back to person ids.
    with op.batch_alter_table('document', recreate='always') as batch_op:
        batch_op.add_column(sa.Column('contact_id', sa.Integer(), nullable=True))
        batch_op.drop_column('owner_id')

    for table in ('task', 'planned_buy'):
        with op.batch_alter_table(table, recreate='always') as batch_op:
            batch_op.drop_column('assignee_id')
            batch_op.add_column(
                sa.Column('assignee_id', sa.Integer(), nullable=True)
            )

    op.rename_table('event_attendee', 'event_attendee_new')
    op.create_table(
        'event_attendee',
        sa.Column('event_id', sa.Integer(), nullable=False),
        sa.Column('person_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['event_id'], ['event.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['person_id'], ['person.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('event_id', 'person_id'),
    )
    op.drop_table('event_attendee_new')
