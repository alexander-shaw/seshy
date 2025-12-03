"""Events router."""
from fastapi import APIRouter, Depends, HTTPException, Query, Header
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import datetime

from ..database import get_db
from ..models import EventItem as EventItemModel, Member as MemberModel
from ..schemas import EventItem, EventItemCreate, EventItemUpdate

router = APIRouter(prefix="/events", tags=["events"])


def get_user_id_from_auth() -> UUID:
    """Extract user ID from auth token (mock implementation)."""
    # TODO: Implement real auth token parsing
    return UUID("00000000-0000-0000-0000-000000000001")


def check_user_can_modify_event(user_id: UUID, event_id: UUID, db: Session) -> bool:
    """Check if user can modify event (host or staff)."""
    member = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.user_id == user_id,
        MemberModel.deleted_at.is_(None),
        MemberModel.role_raw.in_([0, 1])  # host or staff
    ).first()
    return member is not None


@router.get("", response_model=List[EventItem])
async def list_events(
    status: Optional[str] = Query(None, description="Filter by status: upcoming, live, past"),
    user_id: Optional[UUID] = Query(None, description="Filter by user ID (member of)"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """List events with optional filters."""
    query = db.query(EventItemModel).filter(EventItemModel.deleted_at.is_(None))
    
    now = datetime.utcnow()
    
    if status == "upcoming":
        query = query.filter(
            EventItemModel.start_time > now,
            EventItemModel.schedule_status_raw != 2,  # not cancelled
            EventItemModel.schedule_status_raw != 3   # not ended
        )
    elif status == "live":
        query = query.filter(
            EventItemModel.start_time <= now,
            EventItemModel.schedule_status_raw != 2,  # not cancelled
            EventItemModel.schedule_status_raw != 3   # not ended
        ).filter(
            (EventItemModel.end_time.is_(None)) | (EventItemModel.end_time >= now)
        )
    elif status == "past":
        query = query.filter(
            (EventItemModel.end_time < now) | (EventItemModel.schedule_status_raw == 3)
        )
    
    if user_id:
        # Filter events where user is a member
        query = query.join(MemberModel).filter(
            MemberModel.user_id == user_id,
            MemberModel.deleted_at.is_(None)
        )
    
    return query.order_by(EventItemModel.start_time).offset(skip).limit(limit).all()


@router.get("/{event_id}", response_model=EventItem)
async def get_event(event_id: UUID, db: Session = Depends(get_db)):
    """Get event by ID."""
    event = db.query(EventItemModel).filter(
        EventItemModel.id == event_id,
        EventItemModel.deleted_at.is_(None)
    ).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    return event


@router.post("", response_model=EventItem, status_code=201)
async def create_event(
    event: EventItemCreate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Create a new event."""
    # Validate capacity
    if event.max_capacity < 0:
        raise HTTPException(status_code=400, detail="max_capacity must be >= 0")
    
    # Validate times
    if event.start_time and event.end_time and event.start_time >= event.end_time:
        raise HTTPException(status_code=400, detail="start_time must be before end_time")
    
    db_event = EventItemModel(**event.model_dump())
    db.add(db_event)
    
    # Create host member
    host_member = MemberModel(
        role_raw=0,  # host
        user_id=user_id,
        display_name="Host",  # TODO: Get from user profile
        event_id=db_event.id
    )
    db.add(host_member)
    
    db.commit()
    db.refresh(db_event)
    return db_event


@router.put("/{event_id}", response_model=EventItem)
async def update_event(
    event_id: UUID,
    event_update: EventItemUpdate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Update an event."""
    event = db.query(EventItemModel).filter(
        EventItemModel.id == event_id,
        EventItemModel.deleted_at.is_(None)
    ).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check permissions
    if not check_user_can_modify_event(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts and staff can modify events")
    
    # Validate capacity
    if event_update.max_capacity is not None and event_update.max_capacity < 0:
        raise HTTPException(status_code=400, detail="max_capacity must be >= 0")
    
    # Check current capacity
    current_members = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.deleted_at.is_(None)
    ).count()
    
    if event_update.max_capacity is not None and current_members > event_update.max_capacity:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot set max_capacity below current member count ({current_members})"
        )
    
    # Validate times
    start_time = event_update.start_time or event.start_time
    end_time = event_update.end_time or event.end_time
    if start_time and end_time and start_time >= end_time:
        raise HTTPException(status_code=400, detail="start_time must be before end_time")
    
    # Update event status based on times
    now = datetime.utcnow()
    if start_time:
        if start_time > now:
            event.schedule_status_raw = 0  # upcoming
        elif end_time and end_time < now:
            event.schedule_status_raw = 3  # ended
        else:
            event.schedule_status_raw = 1  # live
    
    for key, value in event_update.model_dump(exclude_unset=True).items():
        setattr(event, key, value)
    
    db.commit()
    db.refresh(event)
    return event


@router.delete("/{event_id}", status_code=204)
async def delete_event(
    event_id: UUID,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Soft delete an event."""
    event = db.query(EventItemModel).filter(
        EventItemModel.id == event_id,
        EventItemModel.deleted_at.is_(None)
    ).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check permissions
    if not check_user_can_modify_event(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts and staff can delete events")
    
    event.deleted_at = datetime.utcnow()
    event.schedule_status_raw = 2  # cancelled
    db.commit()
    return None


@router.get("/{event_id}/members", response_model=List)
async def get_event_members(event_id: UUID, db: Session = Depends(get_db)):
    """Get all members of an event."""
    from ..schemas import Member
    
    members = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.deleted_at.is_(None)
    ).all()
    
    return members


@router.get("/{event_id}/media", response_model=List)
async def get_event_media(event_id: UUID, db: Session = Depends(get_db)):
    """Get all media for an event."""
    from ..schemas import Media
    from ..models import Media as MediaModel
    
    media = db.query(MediaModel).filter(
        MediaModel.event_id == event_id,
        MediaModel.deleted_at.is_(None)
    ).order_by(MediaModel.position).all()
    
    return media


@router.get("/{event_id}/vibes", response_model=List)
async def get_event_vibes(event_id: UUID, db: Session = Depends(get_db)):
    """Get all vibes for an event."""
    from ..schemas import Vibe
    from ..models import Vibe as VibeModel, event_vibes
    
    vibes = db.query(VibeModel).join(event_vibes).filter(
        event_vibes.c.event_id == event_id
    ).filter(VibeModel.deleted_at.is_(None)).all()
    
    return vibes









