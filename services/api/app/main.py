from fastapi import FastAPI, Header, HTTPException, Depends
from fastapi.responses import Response
from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from uuid import UUID
from sqlalchemy.orm import Session

from .database import get_db, engine, Base, SessionLocal
from .routers import places, events, members, invites, media, vibes, notifications, tickets, payments
from .services.vibe_seed import upsert_default_vibes

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Seshy API",
    description="API service for Seshy",
    version="0.1.0",
)

# Include routers
app.include_router(places.router)
app.include_router(events.router)
app.include_router(members.router)
app.include_router(invites.router)
app.include_router(media.router)
app.include_router(vibes.router)
app.include_router(notifications.router)
app.include_router(tickets.router)
app.include_router(payments.router)


@app.on_event("startup")
def seed_system_vibes():
    """Ensure default system vibes exist on every boot."""
    db = SessionLocal()
    try:
        upsert_default_vibes(db)
    finally:
        db.close()

# Pydantic models matching iOS DTOs (keeping for backward compatibility)
class PublicProfileDTO(BaseModel):
    id: UUID
    avatarURL: Optional[str] = None
    username: Optional[str] = None
    displayName: str
    bio: Optional[str] = None
    ageYears: Optional[int] = None
    gender: Optional[str] = None
    reputationScore: int = 0
    isVerified: bool
    createdAt: datetime
    updatedAt: datetime
    deletedAt: Optional[datetime] = None
    syncStatusRaw: int
    lastCloudSyncedAt: Optional[datetime] = None
    schemaVersion: int

class PublicProfileUpdateDTO(BaseModel):
    username: Optional[str] = None
    avatarURL: Optional[str] = None
    displayName: str
    bio: Optional[str] = None
    ageYears: Optional[int] = None
    gender: Optional[str] = None
    isVerified: bool
    updatedAt: datetime
    idempotencyKey: str

class UserSettingsDTO(BaseModel):
    id: UUID
    appearanceModeRaw: int
    mapStyleRaw: int
    mapCenterLatitude: float
    mapCenterLongitude: float
    mapZoomLevel: float
    mapStartDate: Optional[datetime] = None
    mapEndDate: Optional[datetime] = None
    mapMaxDistance: Optional[float] = None
    updatedAt: datetime
    schemaVersion: int

class SettingsUpdateDTO(BaseModel):
    appearanceModeRaw: int
    mapStyleRaw: int
    mapCenterLatitude: float
    mapCenterLongitude: float
    mapZoomLevel: float
    mapStartDate: Optional[datetime] = None
    mapEndDate: Optional[datetime] = None
    mapMaxDistance: Optional[float] = None
    updatedAt: datetime
    idempotencyKey: str

class UserLoginDTO(BaseModel):
    id: UUID
    lastLoginAt: Optional[datetime] = None
    phoneE164Hashed: str
    phoneVerifiedAt: Optional[datetime] = None
    emailAddressHashed: Optional[str] = None
    emailDomain: Optional[str] = None
    emailVerifiedAt: Optional[datetime] = None
    updatedAt: datetime
    schemaVersion: int

# In-memory storage for demo purposes (will be replaced with database)
user_public_profile_store: dict[UUID, dict] = {}
user_settings_store: dict[UUID, dict] = {}
user_login_store: dict[UUID, dict] = {}

# ETags for conditional requests
public_profile_etags: dict[UUID, str] = {}
settings_etags: dict[UUID, str] = {}
login_etags: dict[UUID, str] = {}

def generate_etag(data: dict) -> str:
    """Generate ETag from data hash"""
    import hashlib
    data_str = str(sorted(data.items()))
    return hashlib.md5(data_str.encode()).hexdigest()

def get_user_id_from_auth() -> UUID:
    """Extract user ID from auth token (mock implementation)"""
    # TODO: Implement real auth token parsing
    # For now, return a default user ID
    return UUID("00000000-0000-0000-0000-000000000001")

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Seshy API", "version": "0.1.0"}

@app.get("/healthz")
async def healthz():
    """Health check endpoint."""
    return {"status": "ok"}

# PublicProfile endpoints (keeping for backward compatibility - TODO: migrate to database)
@app.get("/me/public-profile", response_model=PublicProfileDTO)
async def get_public_profile(if_none_match: Optional[str] = Header(None, alias="If-None-Match")):
    """Get user public profile with ETag support"""
    user_id = get_user_id_from_auth()
    
    if user_id not in user_public_profile_store:
        raise HTTPException(status_code=404, detail="Public profile not found")
    
    profile = user_public_profile_store[user_id]
    etag = public_profile_etags.get(user_id, generate_etag(profile))
    
    if if_none_match == etag:
        return Response(status_code=304, headers={"ETag": etag})
    
    return Response(
        content=PublicProfileDTO(**profile).model_dump_json(),
        media_type="application/json",
        headers={"ETag": etag}
    )

@app.put("/me/public-profile", response_model=PublicProfileDTO)
async def update_public_profile(update: PublicProfileUpdateDTO, idempotency_key: str = Header(..., alias="Idempotency-Key")):
    """Update user public profile"""
    user_id = get_user_id_from_auth()
    
    # Get existing profile or create new
    if user_id in user_public_profile_store:
        existing = user_public_profile_store[user_id]
        profile_data = {
            "id": user_id,
            "avatarURL": update.avatarURL,
            "username": update.username,
            "displayName": update.displayName,
            "bio": update.bio,
            "ageYears": update.ageYears,
            "gender": update.gender,
            "reputationScore": existing.get("reputationScore", 0),
            "isVerified": update.isVerified,
            "createdAt": existing.get("createdAt", datetime.now()),
            "updatedAt": update.updatedAt,
            "deletedAt": existing.get("deletedAt"),
            "syncStatusRaw": existing.get("syncStatusRaw", 0),
            "lastCloudSyncedAt": datetime.now(),
            "schemaVersion": existing.get("schemaVersion", 1)
        }
    else:
        # Create new profile
        profile_data = {
            "id": user_id,
            "avatarURL": update.avatarURL,
            "username": update.username,
            "displayName": update.displayName,
            "bio": update.bio,
            "ageYears": update.ageYears,
            "gender": update.gender,
            "reputationScore": 0,
            "isVerified": update.isVerified,
            "createdAt": datetime.now(),
            "updatedAt": update.updatedAt,
            "deletedAt": None,
            "syncStatusRaw": 0,
            "lastCloudSyncedAt": datetime.now(),
            "schemaVersion": 1
        }
    
    user_public_profile_store[user_id] = profile_data
    public_profile_etags[user_id] = generate_etag(profile_data)
    
    return PublicProfileDTO(**profile_data)

# Settings endpoints (keeping for backward compatibility - TODO: migrate to database)
@app.get("/me/settings", response_model=UserSettingsDTO)
async def get_settings(if_none_match: Optional[str] = Header(None, alias="If-None-Match")):
    """Get user settings with ETag support"""
    user_id = get_user_id_from_auth()
    
    if user_id not in user_settings_store:
        raise HTTPException(status_code=404, detail="Settings not found")
    
    settings = user_settings_store[user_id]
    etag = settings_etags.get(user_id, generate_etag(settings))
    
    if if_none_match == etag:
        return Response(status_code=304, headers={"ETag": etag})
    
    return Response(
        content=UserSettingsDTO(**settings).model_dump_json(),
        media_type="application/json",
        headers={"ETag": etag}
    )

@app.put("/me/settings", response_model=UserSettingsDTO)
async def update_settings(update: SettingsUpdateDTO, idempotency_key: str = Header(..., alias="Idempotency-Key")):
    """Update user settings"""
    user_id = get_user_id_from_auth()
    
    # Create or update settings
    settings_data = {
        "id": user_id,
        "appearanceModeRaw": update.appearanceModeRaw,
        "mapStyleRaw": update.mapStyleRaw,
        "mapCenterLatitude": update.mapCenterLatitude,
        "mapCenterLongitude": update.mapCenterLongitude,
        "mapZoomLevel": update.mapZoomLevel,
        "mapStartDate": update.mapStartDate,
        "mapEndDate": update.mapEndDate,
        "mapMaxDistance": update.mapMaxDistance,
        "updatedAt": datetime.now(),
        "schemaVersion": 1
    }
    
    user_settings_store[user_id] = settings_data
    settings_etags[user_id] = generate_etag(settings_data)
    
    return UserSettingsDTO(**settings_data)

# Login endpoints (keeping for backward compatibility - TODO: migrate to database)
@app.get("/me/login", response_model=UserLoginDTO)
async def get_login(if_none_match: Optional[str] = Header(None, alias="If-None-Match")):
    """Get user login with ETag support"""
    user_id = get_user_id_from_auth()
    
    if user_id not in user_login_store:
        raise HTTPException(status_code=404, detail="Login not found")
    
    login = user_login_store[user_id]
    etag = login_etags.get(user_id, generate_etag(login))
    
    if if_none_match == etag:
        return Response(status_code=304, headers={"ETag": etag})
    
    return Response(
        content=UserLoginDTO(**login).model_dump_json(),
        media_type="application/json",
        headers={"ETag": etag}
    )

@app.put("/me/login", response_model=UserLoginDTO)
async def upsert_login(login: UserLoginDTO, idempotency_key: str = Header(..., alias="Idempotency-Key")):
    """Upsert user login data (hashed phone/email for contact matching)"""
    user_id = get_user_id_from_auth()
    
    # Upsert login data - focus on hashed phone/email for contact matching
    # lastLoginAt and emailDomain are local-only, not synced
    login_data = {
        "id": login.id,
        "lastLoginAt": None,  # Local-only, not synced
        "phoneE164Hashed": login.phoneE164Hashed,  # For contact matching
        "phoneVerifiedAt": login.phoneVerifiedAt,
        "emailAddressHashed": login.emailAddressHashed,  # For contact matching
        "emailDomain": None,  # Local-only, not synced
        "emailVerifiedAt": login.emailVerifiedAt,
        "updatedAt": datetime.now(),
        "schemaVersion": 1
    }
    
    user_login_store[user_id] = login_data
    login_etags[user_id] = generate_etag(login_data)
    
    return UserLoginDTO(**login_data)
