"""Notifications router."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import datetime

from ..database import get_db
from ..models import UserNotification as UserNotificationModel
from ..schemas import UserNotification, UserNotificationCreate, UserNotificationUpdate

router = APIRouter(prefix="/notifications", tags=["notifications"])


def get_user_id_from_auth() -> UUID:
    """Extract user ID from auth token (mock implementation)."""
    return UUID("00000000-0000-0000-0000-000000000001")


@router.get("", response_model=List[UserNotification])
async def list_notifications(
    unread_only: bool = False,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """List user notifications."""
    query = db.query(UserNotificationModel).filter(
        UserNotificationModel.user_id == user_id
    )
    
    if unread_only:
        query = query.filter(UserNotificationModel.is_unread == True)
    
    return query.order_by(UserNotificationModel.timestamp.desc()).offset(skip).limit(limit).all()


@router.get("/{notification_id}", response_model=UserNotification)
async def get_notification(
    notification_id: UUID,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Get notification by ID."""
    notification = db.query(UserNotificationModel).filter(
        UserNotificationModel.id == notification_id,
        UserNotificationModel.user_id == user_id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    return notification


@router.put("/{notification_id}/read", response_model=UserNotification)
async def mark_notification_read(
    notification_id: UUID,
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Mark notification as read."""
    notification = db.query(UserNotificationModel).filter(
        UserNotificationModel.id == notification_id,
        UserNotificationModel.user_id == user_id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_unread = False
    db.commit()
    db.refresh(notification)
    return notification


@router.put("/read-all", status_code=200)
async def mark_all_read(
    db: Session = Depends(get_db),
    user_id: UUID = Depends(get_user_id_from_auth)
):
    """Mark all notifications as read."""
    db.query(UserNotificationModel).filter(
        UserNotificationModel.user_id == user_id,
        UserNotificationModel.is_unread == True
    ).update({"is_unread": False})
    db.commit()
    return {"message": "All notifications marked as read"}


@router.post("", response_model=UserNotification, status_code=201)
async def create_notification(
    notification: UserNotificationCreate,
    db: Session = Depends(get_db)
):
    """Create a notification (internal use)."""
    db_notification = UserNotificationModel(**notification.model_dump())
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)
    return db_notification


# Helper function to create notifications for events
def create_event_notification(
    db: Session,
    user_id: UUID,
    type_raw: int,
    event_id: UUID,
    event_name: str,
    event_color: str,
    title: str,
    subtitle: Optional[str] = None,
    user_name: Optional[str] = None,
    user_avatar: Optional[str] = None
):
    """Helper to create event-related notifications."""
    notification = UserNotificationModel(
        user_id=user_id,
        type_raw=type_raw,
        event_id=event_id,
        event_name=event_name,
        event_color=event_color,
        title=title,
        subtitle=subtitle,
        user_name=user_name,
        user_avatar=user_avatar,
        is_unread=True
    )
    db.add(notification)
    db.commit()
    return notification

