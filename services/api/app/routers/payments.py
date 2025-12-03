"""Payments router with Stripe integration."""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import datetime
import os
import stripe

from ..database import get_db
from ..models import Payment as PaymentModel, Ticket as TicketModel, EventItem as EventItemModel
from ..schemas import Payment, PaymentCreate, PaymentUpdate

router = APIRouter(prefix="/payments", tags=["payments"])

# Stripe configuration
stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "sk_test_...")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_...")


def get_user_id_from_auth() -> UUID:
    """Extract user ID from auth token (mock implementation)."""
    return UUID("00000000-0000-0000-0000-000000000001")


@router.get("/{payment_id}", response_model=Payment)
async def get_payment(
    payment_id: UUID,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Get payment by ID."""
    payment = db.query(PaymentModel).filter(
        PaymentModel.id == payment_id,
        PaymentModel.user_id == user_id
    ).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    return payment


@router.post("/tickets/{ticket_id}/purchase", response_model=Payment, status_code=201)
async def purchase_ticket(
    ticket_id: UUID,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Purchase a ticket (creates Stripe checkout session)."""
    ticket = db.query(TicketModel).filter(TicketModel.id == ticket_id).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    # Check availability
    if ticket.sold >= ticket.quantity:
        raise HTTPException(status_code=400, detail="Ticket is sold out")
    
    # Check expiration
    if ticket.expires_at and ticket.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Ticket has expired")
    
    # Create payment record
    payment = PaymentModel(
        ticket_id=ticket_id,
        user_id=user_id,
        amount_cents=ticket.price_cents,
        status="pending"
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    
    # Create Stripe Payment Intent
    try:
        intent = stripe.PaymentIntent.create(
            amount=ticket.price_cents,
            currency="usd",
            metadata={
                "payment_id": str(payment.id),
                "ticket_id": str(ticket_id),
                "user_id": str(user_id)
            }
        )
        
        payment.stripe_payment_intent_id = intent.id
        db.commit()
        db.refresh(payment)
        
        return {
            **payment.__dict__,
            "client_secret": intent.client_secret
        }
    except stripe.error.StripeError as e:
        payment.status = "failed"
        db.commit()
        raise HTTPException(status_code=400, detail=f"Stripe error: {str(e)}")


@router.post("/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle Stripe webhook events."""
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Handle the event
    if event["type"] == "payment_intent.succeeded":
        payment_intent = event["data"]["object"]
        payment_id = payment_intent["metadata"].get("payment_id")
        
        if payment_id:
            payment = db.query(PaymentModel).filter(
                PaymentModel.id == UUID(payment_id)
            ).first()
            
            if payment and payment.status == "pending":
                payment.status = "succeeded"
                
                # Update ticket sold count
                ticket = db.query(TicketModel).filter(
                    TicketModel.id == payment.ticket_id
                ).first()
                if ticket:
                    ticket.sold += 1
                
                # Update event capacity if needed
                event = db.query(EventItemModel).filter(
                    EventItemModel.id == ticket.event_id
                ).first()
                if event and event.max_capacity > 0:
                    # Ticket purchase counts toward event capacity
                    pass  # This is handled by member creation
                
                db.commit()
    
    elif event["type"] == "payment_intent.payment_failed":
        payment_intent = event["data"]["object"]
        payment_id = payment_intent["metadata"].get("payment_id")
        
        if payment_id:
            payment = db.query(PaymentModel).filter(
                PaymentModel.id == UUID(payment_id)
            ).first()
            
            if payment:
                payment.status = "failed"
                db.commit()
    
    return {"status": "success"}









