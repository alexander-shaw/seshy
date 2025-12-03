"""Members router."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import datetime

from ..database import get_db
from ..models import Member as MemberModel, EventItem as EventItemModel
from ..schemas import Member, MemberCreate, MemberUpdate

router = APIRouter(prefix="/events/{event_id}/members", tags=["members"])


def get_user_id_from_auth() -> UUID:
    """Extract user ID from auth token (mock implementation)."""
    return UUID("00000000-0000-0000-0000-000000000001")


def check_user_is_host(user_id: UUID, event_id: UUID, db: Session) -> bool:
    """Check if user is a host of the event."""
    member = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.user_id == user_id,
        MemberModel.role_raw == 0,  # host
        MemberModel.deleted_at.is_(None)
    ).first()
    return member is not None


@router.get("", response_model=List[Member])
async def list_members(event_id: UUID, db: Session = Depends(get_db)):
    """List all members of an event."""
    members = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.deleted_at.is_(None)
    ).all()
    
    return members


@router.get("/{member_id}", response_model=Member)
async def get_member(
    event_id: UUID,
    member_id: UUID,
    db: Session = Depends(get_db)
):
    """Get a member by ID."""
    member = db.query(MemberModel).filter(
        MemberModel.id == member_id,
        MemberModel.event_id == event_id,
        MemberModel.deleted_at.is_(None)
    ).first()
    
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    
    return member


@router.post("", response_model=Member, status_code=201)
async def create_member(
    event_id: UUID,
    member: MemberCreate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Add a member to an event (typically from invite approval)."""
    # Verify event exists
    event = db.query(EventItemModel).filter(
        EventItemModel.id == event_id,
        EventItemModel.deleted_at.is_(None)
    ).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check capacity
    current_members = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.deleted_at.is_(None)
    ).count()
    
    if event.max_capacity > 0 and current_members >= event.max_capacity:
        raise HTTPException(status_code=400, detail="Event is at capacity")
    
    # Check if member already exists
    existing = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.user_id == member.user_id,
        MemberModel.deleted_at.is_(None)
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="User is already a member of this event")
    
    db_member = MemberModel(
        **member.model_dump(),
        event_id=event_id
    )
    db.add(db_member)
    db.commit()
    db.refresh(db_member)
    return db_member


@router.put("/{member_id}", response_model=Member)
async def update_member(
    event_id: UUID,
    member_id: UUID,
    member_update: MemberUpdate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Update a member's role or info."""
    member = db.query(MemberModel).filter(
        MemberModel.id == member_id,
        MemberModel.event_id == event_id,
        MemberModel.deleted_at.is_(None)
    ).first()
    
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    
    # Only hosts can modify roles
    if member_update.role_raw is not None and not check_user_is_host(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts can modify member roles")
    
    # Enforce at least one host
    if member_update.role_raw is not None and member.role_raw == 0:  # current member is host
        if member_update.role_raw != 0:  # trying to change from host
            host_count = db.query(MemberModel).filter(
                MemberModel.event_id == event_id,
                MemberModel.role_raw == 0,
                MemberModel.deleted_at.is_(None)
            ).count()
            if host_count <= 1:
                raise HTTPException(
                    status_code=400,
                    detail="Event must have at least one host"
                )
    
    for key, value in member_update.model_dump(exclude_unset=True).items():
        setattr(member, key, value)
    
    db.commit()
    db.refresh(member)
    return member


@router.delete("/{member_id}", status_code=204)
async def delete_member(
    event_id: UUID,
    member_id: UUID,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Remove a member from an event."""
    member = db.query(MemberModel).filter(
        MemberModel.id == member_id,
        MemberModel.event_id == event_id,
        MemberModel.deleted_at.is_(None)
    ).first()
    
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    
    # Only hosts can remove members (or user removing themselves)
    if member.user_id != user_id and not check_user_is_host(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts can remove members")
    
    # Enforce at least one host
    if member.role_raw == 0:  # member is host
        host_count = db.query(MemberModel).filter(
            MemberModel.event_id == event_id,
            MemberModel.role_raw == 0,
            MemberModel.deleted_at.is_(None)
        ).count()
        if host_count <= 1:
            raise HTTPException(
                status_code=400,
                detail="Event must have at least one host"
            )
    
    member.deleted_at = datetime.utcnow()
    db.commit()
    return None









