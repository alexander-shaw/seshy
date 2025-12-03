"""Stripe service for payment processing."""
import os
import stripe
from typing import Optional

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "sk_test_...")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_...")


def create_payment_intent(amount_cents: int, metadata: dict) -> stripe.PaymentIntent:
    """Create a Stripe Payment Intent."""
    return stripe.PaymentIntent.create(
        amount=amount_cents,
        currency="usd",
        metadata=metadata
    )


def get_payment_intent(payment_intent_id: str) -> stripe.PaymentIntent:
    """Retrieve a Stripe Payment Intent."""
    return stripe.PaymentIntent.retrieve(payment_intent_id)


def cancel_payment_intent(payment_intent_id: str) -> stripe.PaymentIntent:
    """Cancel a Stripe Payment Intent."""
    return stripe.PaymentIntent.cancel(payment_intent_id)


def create_refund(charge_id: str, amount_cents: Optional[int] = None) -> stripe.Refund:
    """Create a refund for a charge."""
    params = {"charge": charge_id}
    if amount_cents:
        params["amount"] = amount_cents
    return stripe.Refund.create(**params)









