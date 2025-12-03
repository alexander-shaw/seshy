"""Seed canonical system vibes."""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy import orm

from app.services.vibe_seed import upsert_default_vibes

# revision identifiers, used by Alembic.
revision = "20241119_0001"
down_revision = "20241119_0000"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    session = orm.Session(bind=bind)
    try:
        upsert_default_vibes(session, commit=True)
    finally:
        session.close()


def downgrade() -> None:
    pass

