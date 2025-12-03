"""Invites router."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import datetime, timedelta
import secrets
import string

from ..database import get_db
from ..models import Invite as InviteModel, EventItem as EventItemModel, Member as MemberModel
from ..schemas import Invite, InviteCreate, InviteUpdate

router = APIRouter(prefix="/events/{event_id}/invites", tags=["invites"])


def get_user_id_from_auth() -> UUID:
    """Extract user ID from auth token (mock implementation)."""
    return UUID("00000000-0000-0000-0000-000000000001")


def check_user_can_invite(user_id: UUID, event_id: UUID, db: Session) -> bool:
    """Check if user can invite (host or staff)."""
    member = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.user_id == user_id,
        MemberModel.deleted_at.is_(None),
        MemberModel.role_raw.in_([0, 1])  # host or staff
    ).first()
    return member is not None


def generate_invite_token() -> str:
    """Generate a secure random token for link-based invites."""
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(32))


@router.get("", response_model=List[Invite])
async def list_invites(event_id: UUID, db: Session = Depends(get_db)):
    """List all invites for an event."""
    invites = db.query(InviteModel).filter(
        InviteModel.event_id == event_id,
        InviteModel.deleted_at.is_(None)
    ).all()
    
    return invites


@router.get("/by-token/{token}", response_model=Invite)
async def get_invite_by_token(token: str, db: Session = Depends(get_db)):
    """Get invite by token (for link-based invites)."""
    invite = db.query(InviteModel).filter(
        InviteModel.token == token,
        InviteModel.deleted_at.is_(None)
    ).first()
    
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")
    
    # Check expiration
    if invite.expires_at and invite.expires_at < datetime.utcnow():
        raise HTTPException(status_code=410, detail="Invite has expired")
    
    return invite


@router.post("", response_model=Invite, status_code=201)
async def create_invite(
    event_id: UUID,
    invite: InviteCreate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Create an invite (host/staff only)."""
    # Verify event exists
    event = db.query(EventItemModel).filter(
        EventItemModel.id == event_id,
        EventItemModel.deleted_at.is_(None)
    ).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check permissions
    if not check_user_can_invite(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts and staff can create invites")
    
    # Check if user is already a member
    existing_member = db.query(MemberModel).filter(
        MemberModel.event_id == event_id,
        MemberModel.user_id == invite.user_id,
        MemberModel.deleted_at.is_(None)
    ).first()
    
    if existing_member:
        raise HTTPException(status_code=400, detail="User is already a member of this event")
    
    # Check if invite already exists
    existing_invite = db.query(InviteModel).filter(
        InviteModel.event_id == event_id,
        InviteModel.user_id == invite.user_id,
        InviteModel.deleted_at.is_(None),
        InviteModel.status_raw == 0  # pending
    ).first()
    
    if existing_invite:
        raise HTTPException(status_code=400, detail="Invite already exists for this user")
    
    # Generate token for link-based invites if needed
    token = invite.token
    if not token and invite.type_raw == 0:  # invite type
        token = generate_invite_token()
    
    # Set default expiration (7 days)
    expires_at = invite.expires_at
    if not expires_at:
        expires_at = datetime.utcnow() + timedelta(days=7)
    
    db_invite = InviteModel(
        **invite.model_dump(),
        event_id=event_id,
        token=token,
        expires_at=expires_at
    )
    db.add(db_invite)
    db.commit()
    db.refresh(db_invite)
    return db_invite


@router.put("/{invite_id}", response_model=Invite)
async def update_invite(
    event_id: UUID,
    invite_id: UUID,
    invite_update: InviteUpdate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Update invite status (approve/decline)."""
    invite = db.query(InviteModel).filter(
        InviteModel.id == invite_id,
        InviteModel.event_id == event_id,
        InviteModel.deleted_at.is_(None)
    ).first()
    
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")
    
    # Check expiration
    if invite.expires_at and invite.expires_at < datetime.utcnow():
        raise HTTPException(status_code=410, detail="Invite has expired")
    
    # If approving, check permissions and create member
    if invite_update.status_raw == 1:  # accepted
        # For requests, only hosts/staff can approve
        if invite.type_raw == 1:  # request
            if not check_user_can_invite(user_id, event_id, db):
                raise HTTPException(status_code=403, detail="Only hosts and staff can approve join requests")
        
        # Check event capacity
        event = db.query(EventItemModel).filter(EventItemModel.id == event_id).first()
        current_members = db.query(MemberModel).filter(
            MemberModel.event_id == event_id,
            MemberModel.deleted_at.is_(None)
        ).count()
        
        if event.max_capacity > 0 and current_members >= event.max_capacity:
            raise HTTPException(status_code=400, detail="Event is at capacity")
        
        # Create member
        from ..models import PublicProfile as PublicProfileModel
        user_profile = db.query(PublicProfileModel).filter(
            PublicProfileModel.id == invite.user_id
        ).first()
        
        member = MemberModel(
            role_raw=2,  # guest
            user_id=invite.user_id,
            display_name=user_profile.display_name if user_profile else "Guest",
            username=user_profile.username if user_profile else None,
            avatar_url=user_profile.avatar_url if user_profile else None,
            event_id=event_id
        )
        db.add(member)
    
    for key, value in invite_update.model_dump(exclude_unset=True).items():
        setattr(invite, key, value)
    
    db.commit()
    db.refresh(invite)
    return invite


@router.delete("/{invite_id}", status_code=204)
async def delete_invite(
    event_id: UUID,
    invite_id: UUID,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Cancel an invite."""
    invite = db.query(InviteModel).filter(
        InviteModel.id == invite_id,
        InviteModel.event_id == event_id,
        InviteModel.deleted_at.is_(None)
    ).first()
    
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")
    
    # Only hosts/staff or the invitee can cancel
    if invite.user_id != user_id and not check_user_can_invite(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts/staff or invitee can cancel invites")
    
    invite.deleted_at = datetime.utcnow()
    db.commit()
    return None









