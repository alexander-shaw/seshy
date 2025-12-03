"""Pydantic schemas for request/response models."""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID


# Public Profile Schemas
class PublicProfileBase(BaseModel):
    avatar_url: Optional[str] = None
    username: Optional[str] = None
    display_name: str
    bio: Optional[str] = None
    age_years: Optional[int] = None
    gender: Optional[str] = None
    reputation_score: int = 0
    is_verified: bool = False


class PublicProfileCreate(PublicProfileBase):
    id: UUID


class PublicProfileUpdate(PublicProfileBase):
    display_name: str
    is_verified: bool
    updated_at: datetime
    idempotency_key: str = Field(..., alias="Idempotency-Key")


class PublicProfile(PublicProfileBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    sync_status_raw: int
    last_cloud_synced_at: Optional[datetime] = None
    schema_version: int

    class Config:
        from_attributes = True


# User Settings Schemas
class UserSettingsBase(BaseModel):
    appearance_mode_raw: int
    map_style_raw: int
    map_center_latitude: float
    map_center_longitude: float
    map_zoom_level: float
    map_start_date: Optional[datetime] = None
    map_end_date: Optional[datetime] = None
    map_max_distance: Optional[float] = None


class UserSettingsUpdate(UserSettingsBase):
    updated_at: datetime
    idempotency_key: str = Field(..., alias="Idempotency-Key")


class UserSettings(UserSettingsBase):
    id: UUID
    updated_at: datetime
    schema_version: int

    class Config:
        from_attributes = True


# User Login Schemas
class UserLoginBase(BaseModel):
    phone_e164_hashed: str
    phone_verified_at: Optional[datetime] = None
    email_address_hashed: Optional[str] = None
    email_verified_at: Optional[datetime] = None


class UserLoginCreate(UserLoginBase):
    id: UUID


class UserLogin(UserLoginBase):
    id: UUID
    updated_at: datetime
    schema_version: int

    class Config:
        from_attributes = True


# Place Schemas
class PlaceBase(BaseModel):
    name: str
    details: Optional[str] = None
    street_address: Optional[str] = None
    city: Optional[str] = None
    state_region: Optional[str] = None
    room_number: Optional[str] = None
    latitude: float
    longitude: float
    radius: float
    max_capacity: Optional[int] = None


class PlaceCreate(PlaceBase):
    pass


class PlaceUpdate(PlaceBase):
    pass


class Place(PlaceBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    sync_status_raw: int
    last_cloud_synced_at: Optional[datetime] = None
    schema_version: int

    class Config:
        from_attributes = True


# Vibe Schemas
class VibeBase(BaseModel):
    name: str
    slug: str
    category_raw: int
    system_defined: bool = False
    is_active: bool = True


class VibeCreate(VibeBase):
    pass


class VibeUpdate(VibeBase):
    pass


class Vibe(VibeBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    sync_status_raw: int
    last_cloud_synced_at: Optional[datetime] = None
    schema_version: int

    class Config:
        from_attributes = True


# Event Schemas
class EventItemBase(BaseModel):
    name: str
    details: Optional[str] = None
    brand_color: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    is_all_day: bool = False
    location_id: Optional[UUID] = None
    max_capacity: int = 0
    visibility_raw: int = 0
    schedule_status_raw: int = 0
    invite_link: Optional[str] = None


class EventItemCreate(EventItemBase):
    pass


class EventItemUpdate(EventItemBase):
    pass


class EventItem(EventItemBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    sync_status_raw: int
    last_cloud_synced_at: Optional[datetime] = None
    schema_version: int

    class Config:
        from_attributes = True


# Member Schemas
class MemberBase(BaseModel):
    role_raw: int  # 0=host, 1=staff, 2=guest
    user_id: UUID
    display_name: str
    username: Optional[str] = None
    avatar_url: Optional[str] = None


class MemberCreate(MemberBase):
    event_id: UUID


class MemberUpdate(MemberBase):
    pass


class Member(MemberBase):
    id: UUID
    event_id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    sync_status_raw: int
    last_cloud_synced_at: Optional[datetime] = None
    schema_version: int

    class Config:
        from_attributes = True


# Invite Schemas
class InviteBase(BaseModel):
    user_id: UUID
    type_raw: int  # 0=invite, 1=request
    status_raw: int  # 0=pending, 1=accepted, 2=declined
    token: Optional[str] = None
    expires_at: Optional[datetime] = None


class InviteCreate(InviteBase):
    event_id: UUID


class InviteUpdate(InviteBase):
    pass


class Invite(InviteBase):
    id: UUID
    event_id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    sync_status_raw: int
    last_cloud_synced_at: Optional[datetime] = None
    schema_version: int

    class Config:
        from_attributes = True


# Media Schemas
class MediaBase(BaseModel):
    url: str
    position: int = 0
    mime_type: Optional[str] = None
    average_color_hex: Optional[str] = None
    event_id: Optional[UUID] = None
    user_profile_id: Optional[UUID] = None
    public_profile_id: Optional[UUID] = None


class MediaCreate(MediaBase):
    pass


class MediaUpdate(MediaBase):
    pass


class Media(MediaBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    sync_status_raw: int
    last_cloud_synced_at: Optional[datetime] = None
    schema_version: int

    class Config:
        from_attributes = True


# Notification Schemas
class UserNotificationBase(BaseModel):
    type_raw: int
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None
    event_name: Optional[str] = None
    event_id: Optional[UUID] = None
    event_color: Optional[str] = None
    title: str
    subtitle: Optional[str] = None
    metadata: Optional[str] = None
    primary_action: Optional[str] = None
    secondary_action: Optional[str] = None


class UserNotificationCreate(UserNotificationBase):
    user_id: UUID


class UserNotificationUpdate(BaseModel):
    is_unread: Optional[bool] = None


class UserNotification(UserNotificationBase):
    id: UUID
    user_id: UUID
    timestamp: datetime
    is_unread: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Ticket Schemas
class TicketBase(BaseModel):
    name: str
    price_cents: int
    quantity: int
    expires_at: Optional[datetime] = None


class TicketCreate(TicketBase):
    event_id: UUID


class TicketUpdate(TicketBase):
    pass


class Ticket(TicketBase):
    id: UUID
    event_id: UUID
    sold: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Payment Schemas
class PaymentBase(BaseModel):
    ticket_id: UUID
    amount_cents: int


class PaymentCreate(PaymentBase):
    user_id: UUID


class PaymentUpdate(BaseModel):
    status: str
    stripe_payment_intent_id: Optional[str] = None


class Payment(PaymentBase):
    id: UUID
    user_id: UUID
    stripe_payment_intent_id: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True









