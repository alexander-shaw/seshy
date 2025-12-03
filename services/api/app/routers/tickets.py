"""Tickets router."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from ..database import get_db
from ..models import Ticket as TicketModel, EventItem as EventItemModel, Member as MemberModel
from ..schemas import Ticket, TicketCreate, TicketUpdate

router = APIRouter(prefix="/events/{event_id}/tickets", tags=["tickets"])


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


@router.get("", response_model=List[Ticket])
async def list_tickets(event_id: UUID, db: Session = Depends(get_db)):
    """List all ticket types for an event."""
    tickets = db.query(TicketModel).filter(
        TicketModel.event_id == event_id
    ).all()
    
    return tickets


@router.get("/{ticket_id}", response_model=Ticket)
async def get_ticket(
    event_id: UUID,
    ticket_id: UUID,
    db: Session = Depends(get_db)
):
    """Get ticket by ID."""
    ticket = db.query(TicketModel).filter(
        TicketModel.id == ticket_id,
        TicketModel.event_id == event_id
    ).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    return ticket


@router.post("", response_model=Ticket, status_code=201)
async def create_ticket(
    event_id: UUID,
    ticket: TicketCreate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Create a ticket type (host only)."""
    # Verify event exists
    event = db.query(EventItemModel).filter(
        EventItemModel.id == event_id,
        EventItemModel.deleted_at.is_(None)
    ).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check permissions
    if not check_user_is_host(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts can create tickets")
    
    # Validate price
    if ticket.price_cents < 0:
        raise HTTPException(status_code=400, detail="Price must be >= 0")
    
    # Validate quantity
    if ticket.quantity < 1:
        raise HTTPException(status_code=400, detail="Quantity must be >= 1")
    
    db_ticket = TicketModel(
        **ticket.model_dump(),
        event_id=event_id
    )
    db.add(db_ticket)
    db.commit()
    db.refresh(db_ticket)
    return db_ticket


@router.put("/{ticket_id}", response_model=Ticket)
async def update_ticket(
    event_id: UUID,
    ticket_id: UUID,
    ticket_update: TicketUpdate,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Update a ticket type (host only)."""
    ticket = db.query(TicketModel).filter(
        TicketModel.id == ticket_id,
        TicketModel.event_id == event_id
    ).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    # Check permissions
    if not check_user_is_host(user_id, event_id, db):
        raise HTTPException(status_code=403, detail="Only hosts can update tickets")
    
    # Validate price
    if ticket_update.price_cents is not None and ticket_update.price_cents < 0:
        raise HTTPException(status_code=400, detail="Price must be >= 0")
    
    # Validate quantity (can't set below sold count)
    if ticket_update.quantity is not None:
        if ticket_update.quantity < ticket.sold:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot set quantity below sold count ({ticket.sold})"
            )
    
    for key, value in ticket_update.model_dump(exclude_unset=True).items():
        setattr(ticket, key, value)
    
    db.commit()
    db.refresh(ticket)
    return ticket









