"""Initial database schema for Seshy API."""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "20241119_0000"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "public_profiles",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("avatar_url", sa.String(), nullable=True),
        sa.Column("username", sa.String(), nullable=True),
        sa.Column("display_name", sa.String(), nullable=False),
        sa.Column("bio", sa.Text(), nullable=True),
        sa.Column("age_years", sa.Integer(), nullable=True),
        sa.Column("gender", sa.String(), nullable=True),
        sa.Column("reputation_score", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_verified", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("sync_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("last_cloud_synced_at", sa.DateTime(), nullable=True),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("username", name="uq_public_profiles_username"),
    )
    op.create_index(
        "ix_public_profiles_username",
        "public_profiles",
        ["username"],
        unique=False,
    )

    op.create_table(
        "places",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("details", sa.Text(), nullable=True),
        sa.Column("street_address", sa.String(), nullable=True),
        sa.Column("city", sa.String(), nullable=True),
        sa.Column("state_region", sa.String(), nullable=True),
        sa.Column("room_number", sa.String(), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("radius", sa.Float(), nullable=False),
        sa.Column("max_capacity", sa.BigInteger(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("sync_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("last_cloud_synced_at", sa.DateTime(), nullable=True),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "vibes",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("slug", sa.String(), nullable=False),
        sa.Column("category_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("system_defined", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("sync_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("last_cloud_synced_at", sa.DateTime(), nullable=True),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug", name="uq_vibes_slug"),
    )
    op.create_index(
        "ix_vibes_slug",
        "vibes",
        ["slug"],
        unique=True,
    )

    op.create_table(
        "event_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("schedule_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("details", sa.Text(), nullable=True),
        sa.Column("brand_color", sa.String(), nullable=False),
        sa.Column("start_time", sa.DateTime(), nullable=True),
        sa.Column("end_time", sa.DateTime(), nullable=True),
        sa.Column("duration_minutes", sa.BigInteger(), nullable=True),
        sa.Column("is_all_day", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("location_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("max_capacity", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("visibility_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("invite_link", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("sync_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("last_cloud_synced_at", sa.DateTime(), nullable=True),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.ForeignKeyConstraint(["location_id"], ["places.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "user_logins",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("phone_e164_hashed", sa.String(), nullable=False),
        sa.Column("phone_verified_at", sa.DateTime(), nullable=True),
        sa.Column("email_address_hashed", sa.String(), nullable=True),
        sa.Column("email_verified_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.ForeignKeyConstraint(["user_id"], ["public_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", name="uq_user_logins_user_id"),
    )
    op.create_index(
        "ix_user_logins_phone_e164_hashed",
        "user_logins",
        ["phone_e164_hashed"],
        unique=False,
    )
    op.create_index(
        "ix_user_logins_email_address_hashed",
        "user_logins",
        ["email_address_hashed"],
        unique=False,
    )

    op.create_table(
        "user_settings",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("appearance_mode_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("map_style_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("map_center_latitude", sa.Float(), nullable=False),
        sa.Column("map_center_longitude", sa.Float(), nullable=False),
        sa.Column("map_zoom_level", sa.Float(), nullable=False),
        sa.Column("map_start_date", sa.DateTime(), nullable=True),
        sa.Column("map_end_date", sa.DateTime(), nullable=True),
        sa.Column("map_max_distance", sa.Float(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.ForeignKeyConstraint(["user_id"], ["public_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", name="uq_user_settings_user_id"),
    )

    op.create_table(
        "event_vibes",
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("vibe_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.ForeignKeyConstraint(["event_id"], ["event_items.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["vibe_id"], ["vibes.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("event_id", "vibe_id"),
    )

    op.create_table(
        "members",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("role_raw", sa.SmallInteger(), nullable=False, server_default="2"),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("display_name", sa.String(), nullable=False),
        sa.Column("username", sa.String(), nullable=True),
        sa.Column("avatar_url", sa.String(), nullable=True),
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("sync_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("last_cloud_synced_at", sa.DateTime(), nullable=True),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.ForeignKeyConstraint(["event_id"], ["event_items.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["public_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "invites",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("type_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("token", sa.String(), nullable=True),
        sa.Column("expires_at", sa.DateTime(), nullable=True),
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("sync_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("last_cloud_synced_at", sa.DateTime(), nullable=True),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.ForeignKeyConstraint(["event_id"], ["event_items.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["public_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_invites_token",
        "invites",
        ["token"],
        unique=True,
    )

    op.create_table(
        "media",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("url", sa.String(), nullable=False),
        sa.Column("position", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("mime_type", sa.String(), nullable=True),
        sa.Column("average_color_hex", sa.String(), nullable=True),
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("user_profile_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("public_profile_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("sync_status_raw", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("last_cloud_synced_at", sa.DateTime(), nullable=True),
        sa.Column("schema_version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.ForeignKeyConstraint(["event_id"], ["event_items.id"]),
        sa.ForeignKeyConstraint(["public_profile_id"], ["public_profiles.id"]),
        sa.ForeignKeyConstraint(["user_profile_id"], ["public_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "user_notifications",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("type_raw", sa.SmallInteger(), nullable=False),
        sa.Column("timestamp", sa.DateTime(), nullable=False),
        sa.Column("is_unread", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("user_name", sa.String(), nullable=True),
        sa.Column("user_avatar", sa.String(), nullable=True),
        sa.Column("event_name", sa.String(), nullable=True),
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("event_color", sa.String(), nullable=True),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("subtitle", sa.Text(), nullable=True),
        sa.Column("metadata_json", sa.Text(), nullable=True),
        sa.Column("primary_action", sa.String(), nullable=True),
        sa.Column("secondary_action", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["event_id"], ["event_items.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["public_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_user_notifications_user_id",
        "user_notifications",
        ["user_id"],
        unique=False,
    )

    op.create_table(
        "tickets",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("price_cents", sa.BigInteger(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("sold", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("expires_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["event_id"], ["event_items.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "payments",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("ticket_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("stripe_payment_intent_id", sa.String(), nullable=True),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("amount_cents", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["ticket_id"], ["tickets.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["public_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_payments_stripe_payment_intent_id",
        "payments",
        ["stripe_payment_intent_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("ix_payments_stripe_payment_intent_id", table_name="payments")
    op.drop_table("payments")

    op.drop_table("tickets")

    op.drop_index("ix_user_notifications_user_id", table_name="user_notifications")
    op.drop_table("user_notifications")

    op.drop_table("media")

    op.drop_index("ix_invites_token", table_name="invites")
    op.drop_table("invites")

    op.drop_table("members")

    op.drop_table("event_vibes")

    op.drop_table("user_settings")

    op.drop_index("ix_user_logins_email_address_hashed", table_name="user_logins")
    op.drop_index("ix_user_logins_phone_e164_hashed", table_name="user_logins")
    op.drop_table("user_logins")

    op.drop_table("event_items")

    op.drop_index("ix_vibes_slug", table_name="vibes")
    op.drop_table("vibes")

    op.drop_table("places")

    op.drop_index("ix_public_profiles_username", table_name="public_profiles")
    op.drop_table("public_profiles")

