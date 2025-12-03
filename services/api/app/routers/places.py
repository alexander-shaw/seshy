"""Places router."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from math import radians, cos, sin, asin, sqrt

from ..database import get_db
from ..models import Place as PlaceModel
from ..schemas import Place, PlaceCreate, PlaceUpdate

router = APIRouter(prefix="/places", tags=["places"])


def haversine(lat1, lon1, lat2, lon2):
    """Calculate distance between two points in kilometers."""
    R = 6371  # Earth radius in kilometers
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    return R * c


@router.get("", response_model=List[Place])
async def list_places(
    latitude: Optional[float] = Query(None, description="Center latitude for radius search"),
    longitude: Optional[float] = Query(None, description="Center longitude for radius search"),
    radius_km: Optional[float] = Query(None, description="Search radius in kilometers"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """List places, optionally filtered by location."""
    query = db.query(PlaceModel).filter(PlaceModel.deleted_at.is_(None))
    
    if latitude is not None and longitude is not None and radius_km is not None:
        # Location-based search - filter by approximate bounding box first
        # Then calculate exact distance
        places = query.all()
        results = []
        for place in places:
            distance = haversine(latitude, longitude, place.latitude, place.longitude)
            if distance <= radius_km:
                results.append(place)
        return results[skip:skip+limit]
    
    return query.offset(skip).limit(limit).all()


@router.get("/{place_id}", response_model=Place)
async def get_place(place_id: UUID, db: Session = Depends(get_db)):
    """Get place by ID."""
    place = db.query(PlaceModel).filter(
        PlaceModel.id == place_id,
        PlaceModel.deleted_at.is_(None)
    ).first()
    
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    return place


@router.post("", response_model=Place, status_code=201)
async def create_place(place: PlaceCreate, db: Session = Depends(get_db)):
    """Create a new place."""
    # Validate coordinates
    if not (-90 <= place.latitude <= 90):
        raise HTTPException(status_code=400, detail="Latitude must be between -90 and 90")
    if not (-180 <= place.longitude <= 180):
        raise HTTPException(status_code=400, detail="Longitude must be between -180 and 180")
    
    db_place = PlaceModel(**place.model_dump())
    db.add(db_place)
    db.commit()
    db.refresh(db_place)
    return db_place


@router.put("/{place_id}", response_model=Place)
async def update_place(
    place_id: UUID,
    place_update: PlaceUpdate,
    db: Session = Depends(get_db)
):
    """Update a place."""
    place = db.query(PlaceModel).filter(
        PlaceModel.id == place_id,
        PlaceModel.deleted_at.is_(None)
    ).first()
    
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    # Validate coordinates if provided
    if place_update.latitude is not None and not (-90 <= place_update.latitude <= 90):
        raise HTTPException(status_code=400, detail="Latitude must be between -90 and 90")
    if place_update.longitude is not None and not (-180 <= place_update.longitude <= 180):
        raise HTTPException(status_code=400, detail="Longitude must be between -180 and 180")
    
    for key, value in place_update.model_dump(exclude_unset=True).items():
        setattr(place, key, value)
    
    db.commit()
    db.refresh(place)
    return place


@router.delete("/{place_id}", status_code=204)
async def delete_place(place_id: UUID, db: Session = Depends(get_db)):
    """Soft delete a place."""
    from datetime import datetime
    
    place = db.query(PlaceModel).filter(
        PlaceModel.id == place_id,
        PlaceModel.deleted_at.is_(None)
    ).first()
    
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    place.deleted_at = datetime.utcnow()
    db.commit()
    return None









