"""Media router."""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import datetime
import os
from google.cloud import storage

from ..database import get_db
from ..models import Media as MediaModel, EventItem as EventItemModel
from ..schemas import Media, MediaCreate, MediaUpdate

router = APIRouter(prefix="/media", tags=["media"])

# Google Cloud Storage configuration
GCS_BUCKET_NAME = os.getenv("GCS_BUCKET_NAME", "seshy-media")
GCS_CLIENT = storage.Client() if os.getenv("GOOGLE_APPLICATION_CREDENTIALS") else None


def upload_to_gcs(file_data: bytes, filename: str, content_type: str) -> str:
    """Upload file to Google Cloud Storage and return public URL."""
    if not GCS_CLIENT:
        # Fallback to local storage for development
        os.makedirs("uploads", exist_ok=True)
        filepath = f"uploads/{filename}"
        with open(filepath, "wb") as f:
            f.write(file_data)
        return f"http://localhost:8000/uploads/{filename}"
    
    bucket = GCS_CLIENT.bucket(GCS_BUCKET_NAME)
    blob = bucket.blob(filename)
    blob.upload_from_string(file_data, content_type=content_type)
    blob.make_public()
    return blob.public_url


def calculate_average_color(file_data: bytes) -> Optional[str]:
    """Calculate average color hex from image (simplified - would use PIL in production)."""
    # TODO: Implement actual color calculation using PIL/Pillow
    return None


@router.get("/events/{event_id}", response_model=List[Media])
async def list_event_media(event_id: UUID, db: Session = Depends(get_db)):
    """List all media for an event."""
    media = db.query(MediaModel).filter(
        MediaModel.event_id == event_id,
        MediaModel.deleted_at.is_(None)
    ).order_by(MediaModel.position).all()
    
    return media


@router.get("/{media_id}", response_model=Media)
async def get_media(media_id: UUID, db: Session = Depends(get_db)):
    """Get media by ID."""
    media = db.query(MediaModel).filter(
        MediaModel.id == media_id,
        MediaModel.deleted_at.is_(None)
    ).first()
    
    if not media:
        raise HTTPException(status_code=404, detail="Media not found")
    
    return media


@router.post("", response_model=Media, status_code=201)
async def upload_media(
    file: UploadFile = File(...),
    event_id: Optional[UUID] = Form(None),
    user_profile_id: Optional[UUID] = Form(None),
    public_profile_id: Optional[UUID] = Form(None),
    position: int = Form(0),
    db: Session = Depends(get_db)
):
    """Upload media file."""
    # Validate exactly one relationship is set
    relationship_count = sum([
        event_id is not None,
        user_profile_id is not None,
        public_profile_id is not None
    ])
    
    if relationship_count != 1:
        raise HTTPException(
            status_code=400,
            detail="Exactly one of event_id, user_profile_id, or public_profile_id must be provided"
        )
    
    # Validate file type (only images allowed)
    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"File type {file.content_type} not allowed. Allowed types: {allowed_types}"
        )
    
    # Validate file size (10MB max)
    file_data = await file.read()
    if len(file_data) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File size exceeds 10MB limit")
    
    # Generate filename
    file_ext = os.path.splitext(file.filename)[1] if file.filename else ".bin"
    filename = f"{UUID().hex}{file_ext}"
    
    # Upload to storage
    url = upload_to_gcs(file_data, filename, file.content_type)
    
    # Calculate average color (for images)
    average_color_hex = None
    if file.content_type and file.content_type.startswith("image/"):
        average_color_hex = calculate_average_color(file_data)
    
    # Create media record
    media_data = {
        "url": url,
        "position": position,
        "mime_type": file.content_type,
        "average_color_hex": average_color_hex,
        "event_id": event_id,
        "user_profile_id": user_profile_id,
        "public_profile_id": public_profile_id
    }
    
    db_media = MediaModel(**media_data)
    db.add(db_media)
    db.commit()
    db.refresh(db_media)
    return db_media


@router.put("/{media_id}", response_model=Media)
async def update_media(
    media_id: UUID,
    media_update: MediaUpdate,
    db: Session = Depends(get_db)
):
    """Update media metadata."""
    media = db.query(MediaModel).filter(
        MediaModel.id == media_id,
        MediaModel.deleted_at.is_(None)
    ).first()
    
    if not media:
        raise HTTPException(status_code=404, detail="Media not found")
    
    for key, value in media_update.model_dump(exclude_unset=True).items():
        setattr(media, key, value)
    
    db.commit()
    db.refresh(media)
    return media


@router.delete("/{media_id}", status_code=204)
async def delete_media(media_id: UUID, db: Session = Depends(get_db)):
    """Delete media."""
    media = db.query(MediaModel).filter(
        MediaModel.id == media_id,
        MediaModel.deleted_at.is_(None)
    ).first()
    
    if not media:
        raise HTTPException(status_code=404, detail="Media not found")
    
    # TODO: Delete file from storage
    
    media.deleted_at = datetime.utcnow()
    db.commit()
    return None









