"""SQLAlchemy database models."""
from sqlalchemy import Column, String, Integer, BigInteger, Boolean, DateTime, ForeignKey, Text, Float, SmallInteger
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid
from .database import Base


class PublicProfile(Base):
    """Public user profile."""
    __tablename__ = "public_profiles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    avatar_url = Column(String, nullable=True)
    username = Column(String, nullable=True, unique=True, index=True)
    display_name = Column(String, nullable=False)
    bio = Column(Text, nullable=True)
    age_years = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    reputation_score = Column(Integer, default=0, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    deleted_at = Column(DateTime, nullable=True)
    sync_status_raw = Column(SmallInteger, default=0, nullable=False)
    last_cloud_synced_at = Column(DateTime, nullable=True)
    schema_version = Column(SmallInteger, default=1, nullable=False)


class UserSettings(Base):
    """User settings."""
    __tablename__ = "user_settings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=False, unique=True)
    appearance_mode_raw = Column(SmallInteger, default=0, nullable=False)
    map_style_raw = Column(SmallInteger, default=0, nullable=False)
    map_center_latitude = Column(Float, nullable=False)
    map_center_longitude = Column(Float, nullable=False)
    map_zoom_level = Column(Float, nullable=False)
    map_start_date = Column(DateTime, nullable=True)
    map_end_date = Column(DateTime, nullable=True)
    map_max_distance = Column(Float, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    user = relationship("PublicProfile", backref="settings")


class UserLogin(Base):
    """User login information."""
    __tablename__ = "user_logins"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=False, unique=True)
    phone_e164_hashed = Column(String, nullable=False, index=True)
    phone_verified_at = Column(DateTime, nullable=True)
    email_address_hashed = Column(String, nullable=True, index=True)
    email_verified_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    user = relationship("PublicProfile", backref="login")


class Place(Base):
    """Place/venue location."""
    __tablename__ = "places"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    details = Column(Text, nullable=True)
    street_address = Column(String, nullable=True)
    city = Column(String, nullable=True)
    state_region = Column(String, nullable=True)
    room_number = Column(String, nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    radius = Column(Float, nullable=False)
    max_capacity = Column(BigInteger, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    deleted_at = Column(DateTime, nullable=True)
    sync_status_raw = Column(SmallInteger, default=0, nullable=False)
    last_cloud_synced_at = Column(DateTime, nullable=True)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    events = relationship("EventItem", back_populates="location")


class Vibe(Base):
    """Vibe/tag for events."""
    __tablename__ = "vibes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    slug = Column(String, nullable=False, unique=True, index=True)
    category_raw = Column(SmallInteger, default=0, nullable=False)
    system_defined = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    deleted_at = Column(DateTime, nullable=True)
    sync_status_raw = Column(SmallInteger, default=0, nullable=False)
    last_cloud_synced_at = Column(DateTime, nullable=True)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    events = relationship("EventItem", secondary="event_vibes", back_populates="vibes")


class EventItem(Base):
    """Event."""
    __tablename__ = "event_items"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    schedule_status_raw = Column(SmallInteger, default=0, nullable=False)
    name = Column(String, nullable=False)
    details = Column(Text, nullable=True)
    brand_color = Column(String, nullable=False)
    start_time = Column(DateTime, nullable=True)
    end_time = Column(DateTime, nullable=True)
    duration_minutes = Column(BigInteger, nullable=True)
    is_all_day = Column(Boolean, default=False, nullable=False)
    location_id = Column(UUID(as_uuid=True), ForeignKey("places.id"), nullable=True)
    max_capacity = Column(BigInteger, default=0, nullable=False)
    visibility_raw = Column(SmallInteger, default=0, nullable=False)
    invite_link = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    deleted_at = Column(DateTime, nullable=True)
    sync_status_raw = Column(SmallInteger, default=0, nullable=False)
    last_cloud_synced_at = Column(DateTime, nullable=True)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    location = relationship("Place", back_populates="events")
    members = relationship("Member", back_populates="event", cascade="all, delete-orphan")
    invites = relationship("Invite", back_populates="event", cascade="all, delete-orphan")
    media = relationship("Media", back_populates="event", cascade="all, delete-orphan")
    vibes = relationship("Vibe", secondary="event_vibes", back_populates="events")


# Association table for many-to-many relationship between events and vibes
from sqlalchemy import Table
event_vibes = Table(
    "event_vibes",
    Base.metadata,
    Column("event_id", UUID(as_uuid=True), ForeignKey("event_items.id"), primary_key=True),
    Column("vibe_id", UUID(as_uuid=True), ForeignKey("vibes.id"), primary_key=True),
)


class Member(Base):
    """Event member."""
    __tablename__ = "members"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role_raw = Column(SmallInteger, default=2, nullable=False)  # 0=host, 1=staff, 2=guest
    user_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=False)
    display_name = Column(String, nullable=False)
    username = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    event_id = Column(UUID(as_uuid=True), ForeignKey("event_items.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    deleted_at = Column(DateTime, nullable=True)
    sync_status_raw = Column(SmallInteger, default=0, nullable=False)
    last_cloud_synced_at = Column(DateTime, nullable=True)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    event = relationship("EventItem", back_populates="members")
    user = relationship("PublicProfile", backref="memberships")


class Invite(Base):
    """Event invitation."""
    __tablename__ = "invites"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=False)
    type_raw = Column(SmallInteger, default=0, nullable=False)  # 0=invite, 1=request
    status_raw = Column(SmallInteger, default=0, nullable=False)  # 0=pending, 1=accepted, 2=declined
    token = Column(String, nullable=True, unique=True, index=True)
    expires_at = Column(DateTime, nullable=True)
    event_id = Column(UUID(as_uuid=True), ForeignKey("event_items.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    deleted_at = Column(DateTime, nullable=True)
    sync_status_raw = Column(SmallInteger, default=0, nullable=False)
    last_cloud_synced_at = Column(DateTime, nullable=True)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    event = relationship("EventItem", back_populates="invites")
    user = relationship("PublicProfile", backref="invites")


class Media(Base):
    """Media (images/videos) for events or profiles."""
    __tablename__ = "media"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    url = Column(String, nullable=False)
    position = Column(SmallInteger, default=0, nullable=False)
    mime_type = Column(String, nullable=True)
    average_color_hex = Column(String, nullable=True)
    event_id = Column(UUID(as_uuid=True), ForeignKey("event_items.id"), nullable=True)
    user_profile_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=True)
    public_profile_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    deleted_at = Column(DateTime, nullable=True)
    sync_status_raw = Column(SmallInteger, default=0, nullable=False)
    last_cloud_synced_at = Column(DateTime, nullable=True)
    schema_version = Column(SmallInteger, default=1, nullable=False)
    
    event = relationship("EventItem", back_populates="media")
    user_profile = relationship("PublicProfile", foreign_keys=[user_profile_id], backref="user_media")
    public_profile = relationship("PublicProfile", foreign_keys=[public_profile_id], backref="public_media")


class UserNotification(Base):
    """User notification."""
    __tablename__ = "user_notifications"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=False, index=True)
    type_raw = Column(SmallInteger, nullable=False)  # NotificationType enum
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_unread = Column(Boolean, default=True, nullable=False)
    user_name = Column(String, nullable=True)
    user_avatar = Column(String, nullable=True)
    event_name = Column(String, nullable=True)
    event_id = Column(UUID(as_uuid=True), ForeignKey("event_items.id"), nullable=True)
    event_color = Column(String, nullable=True)
    title = Column(String, nullable=False)
    subtitle = Column(Text, nullable=True)
    metadata_json = Column("metadata", Text, nullable=True)  # JSON string
    primary_action = Column(String, nullable=True)
    secondary_action = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    user = relationship("PublicProfile", backref="notifications")
    event = relationship("EventItem", backref="notifications")


class Ticket(Base):
    """Ticket type for events."""
    __tablename__ = "tickets"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_id = Column(UUID(as_uuid=True), ForeignKey("event_items.id"), nullable=False)
    name = Column(String, nullable=False)
    price_cents = Column(BigInteger, nullable=False)
    quantity = Column(Integer, nullable=False)
    sold = Column(Integer, default=0, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    event = relationship("EventItem", backref="tickets")
    payments = relationship("Payment", back_populates="ticket")


class Payment(Base):
    """Payment for tickets."""
    __tablename__ = "payments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ticket_id = Column(UUID(as_uuid=True), ForeignKey("tickets.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("public_profiles.id"), nullable=False)
    stripe_payment_intent_id = Column(String, nullable=True, unique=True, index=True)
    status = Column(String, nullable=False)  # pending, succeeded, failed, refunded
    amount_cents = Column(BigInteger, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    ticket = relationship("Ticket", back_populates="payments")
    user = relationship("PublicProfile", backref="payments")








