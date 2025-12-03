"""Vibes router."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import datetime
import re

from ..database import get_db
from ..models import (
    Vibe as VibeModel,
    EventItem as EventItemModel,
    PublicProfile as PublicProfileModel,
    event_vibes,
)
from ..schemas import Vibe, VibeCreate, VibeUpdate

router = APIRouter(prefix="/vibes", tags=["vibes"])

MIN_REPUTATION_FOR_CUSTOM_VIBE = 200


def get_user_id_from_auth() -> UUID:
    """Extract user ID from auth token (mock implementation)."""
    return UUID("00000000-0000-0000-0000-000000000001")


def slugify(text: str) -> str:
    """Convert text to URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '-', text)
    return text


@router.get("", response_model=List[Vibe])
async def list_vibes(
    active_only: bool = True,
    system_only: bool = False,
    db: Session = Depends(get_db)
):
    """List all vibes."""
    query = db.query(VibeModel).filter(VibeModel.deleted_at.is_(None))
    
    if active_only:
        query = query.filter(VibeModel.is_active == True)
    
    if system_only:
        query = query.filter(VibeModel.system_defined == True)
    
    return query.all()


@router.get("/{vibe_id}", response_model=Vibe)
async def get_vibe(vibe_id: UUID, db: Session = Depends(get_db)):
    """Get vibe by ID."""
    vibe = db.query(VibeModel).filter(
        VibeModel.id == vibe_id,
        VibeModel.deleted_at.is_(None)
    ).first()
    
    if not vibe:
        raise HTTPException(status_code=404, detail="Vibe not found")
    
    return vibe


@router.post("", response_model=Vibe, status_code=201)
async def create_vibe(
    vibe: VibeCreate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth),
):
    """Create a vibe (user-created if system_defined=False)."""
    # Generate slug if not provided
    slug = vibe.slug or slugify(vibe.name)
    
    # Check if slug already exists
    existing = db.query(VibeModel).filter(
        VibeModel.slug == slug,
        VibeModel.deleted_at.is_(None)
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail=f"Vibe with slug '{slug}' already exists")
    
    # System vibes cannot be created via API
    if vibe.system_defined:
        raise HTTPException(status_code=403, detail="System vibes cannot be created via API")

    profile = db.query(PublicProfileModel).filter(
        PublicProfileModel.id == user_id,
        PublicProfileModel.deleted_at.is_(None)
    ).first()

    if not profile:
        raise HTTPException(status_code=403, detail="User profile not found")

    if profile.reputation_score < MIN_REPUTATION_FOR_CUSTOM_VIBE:
        raise HTTPException(status_code=403, detail="Insufficient reputation to create vibe")
    
    db_vibe = VibeModel(
        **vibe.model_dump(),
        slug=slug
    )
    db.add(db_vibe)
    db.commit()
    db.refresh(db_vibe)
    return db_vibe


@router.put("/{vibe_id}", response_model=Vibe)
async def update_vibe(
    vibe_id: UUID,
    vibe_update: VibeUpdate,
    db: Session = Depends(get_db)
):
    """Update a vibe."""
    vibe = db.query(VibeModel).filter(
        VibeModel.id == vibe_id,
        VibeModel.deleted_at.is_(None)
    ).first()
    
    if not vibe:
        raise HTTPException(status_code=404, detail="Vibe not found")
    
    # System vibes cannot be modified
    if vibe.system_defined:
        raise HTTPException(status_code=403, detail="System vibes cannot be modified")
    
    # Check slug uniqueness if changing
    if vibe_update.slug and vibe_update.slug != vibe.slug:
        existing = db.query(VibeModel).filter(
            VibeModel.slug == vibe_update.slug,
            VibeModel.id != vibe_id,
            VibeModel.deleted_at.is_(None)
        ).first()
        
        if existing:
            raise HTTPException(status_code=400, detail=f"Vibe with slug '{vibe_update.slug}' already exists")
    
    for key, value in vibe_update.model_dump(exclude_unset=True).items():
        setattr(vibe, key, value)
    
    db.commit()
    db.refresh(vibe)
    return vibe


@router.post("/events/{event_id}/vibes/{vibe_id}", status_code=201)
async def add_vibe_to_event(
    event_id: UUID,
    vibe_id: UUID,
    db: Session = Depends(get_db)
):
    """Add a vibe to an event."""
    event = db.query(EventItemModel).filter(
        EventItemModel.id == event_id,
        EventItemModel.deleted_at.is_(None)
    ).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    vibe = db.query(VibeModel).filter(
        VibeModel.id == vibe_id,
        VibeModel.deleted_at.is_(None),
        VibeModel.is_active == True
    ).first()
    
    if not vibe:
        raise HTTPException(status_code=404, detail="Vibe not found")
    
    # Check if already associated
    from sqlalchemy import select
    stmt = select(event_vibes).where(
        event_vibes.c.event_id == event_id,
        event_vibes.c.vibe_id == vibe_id
    )
    result = db.execute(stmt).first()
    
    if result:
        raise HTTPException(status_code=400, detail="Vibe is already associated with this event")
    
    # Add association
    stmt = event_vibes.insert().values(event_id=event_id, vibe_id=vibe_id)
    db.execute(stmt)
    db.commit()
    
    return {"message": "Vibe added to event"}


@router.delete("/events/{event_id}/vibes/{vibe_id}", status_code=204)
async def remove_vibe_from_event(
    event_id: UUID,
    vibe_id: UUID,
    db: Session = Depends(get_db)
):
    """Remove a vibe from an event."""
    from sqlalchemy import delete
    
    stmt = delete(event_vibes).where(
        event_vibes.c.event_id == event_id,
        event_vibes.c.vibe_id == vibe_id
    )
    result = db.execute(stmt)
    db.commit()
    
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Vibe is not associated with this event")
    
    return None









