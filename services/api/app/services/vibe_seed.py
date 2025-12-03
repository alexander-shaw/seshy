"""Utilities for seeding canonical system vibes."""

from __future__ import annotations

from typing import Iterable, Mapping

from sqlalchemy.orm import Session

from ..database import SessionLocal
from ..models import Vibe
from ..seed_data import DEFAULT_VIBES


def upsert_default_vibes(db: Session, *, commit: bool = True) -> dict[str, int]:
    """Ensure every default vibe exists as a system-defined row."""
    existing = {
        vibe.slug: vibe
        for vibe in db.query(Vibe).filter(Vibe.system_defined.is_(True))
    }
    desired_slugs = set()
    inserted = 0
    updated = 0
    inactivated = 0

    for payload in DEFAULT_VIBES:
        slug = payload["slug"]
        desired_slugs.add(slug)
        vibe = existing.get(slug)

        if vibe:
            changed = False
            if (
                vibe.name != payload["name"]
                or vibe.category_raw != payload["category_raw"]
                or vibe.is_active != payload["is_active"]
            ):
                vibe.name = payload["name"]
                vibe.category_raw = payload["category_raw"]
                vibe.is_active = payload["is_active"]
                changed = True

            if vibe.deleted_at is not None:
                vibe.deleted_at = None
                changed = True

            if not vibe.system_defined:
                vibe.system_defined = True
                changed = True

            if changed:
                updated += 1
            continue

        db.add(
            Vibe(
                name=payload["name"],
                slug=slug,
                category_raw=payload["category_raw"],
                system_defined=True,
                is_active=payload["is_active"],
            )
        )
        inserted += 1

    # Inactivate system vibes that are no longer part of the canonical list.
    for slug, vibe in existing.items():
        if slug in desired_slugs:
            continue
        if vibe.is_active:
            vibe.is_active = False
            inactivated += 1

    if commit:
        db.commit()

    return {"inserted": inserted, "updated": updated, "inactivated": inactivated}


def run_cli() -> None:
    """CLI entry point used by scripts/Makefile."""
    with SessionLocal() as session:
        summary = upsert_default_vibes(session)
        print(
            "Seeded system vibes "
            f"(inserted={summary['inserted']}, "
            f"updated={summary['updated']}, "
            f"inactivated={summary['inactivated']})"
        )


if __name__ == "__main__":
    run_cli()

