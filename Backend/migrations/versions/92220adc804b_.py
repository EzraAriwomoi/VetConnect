"""empty message

Revision ID: 92220adc804b
Revises: a80bfc2ed2ea
Create Date: 2025-03-19 01:45:55.004646

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql

# revision identifiers, used by Alembic.
revision = '92220adc804b'
down_revision = 'a80bfc2ed2ea'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('animal', schema=None) as batch_op:
        batch_op.add_column(sa.Column('date_of_birth', sa.Date(), nullable=False))
        batch_op.drop_column('age')

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('animal', schema=None) as batch_op:
        batch_op.add_column(sa.Column('age', mysql.INTEGER(), autoincrement=False, nullable=False))
        batch_op.drop_column('date_of_birth')

    # ### end Alembic commands ###
