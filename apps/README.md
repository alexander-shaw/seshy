
# Apps

## iOS

### BEST PRACTICES

- Use Core Data entities in ViewModels and Views.
- Implement SyncTrackable on all Core Data entities.
- Keep DTOs at repository boundaries only.  (Do not use or expose DTOs in ViewModels or Views!)
- Use computed properties for enum conversions.
- Handle Core Data context operations properly.
- Use @MainActor for ViewModels.

### BENEFITS

1. **Simplicity**: Single source of truth with Core Data entities.
2. **Performance**: No unnecessary conversions between layers.
3. **iOS Best Practices**: Follows standard iOS architecture patterns.
4. **Type Safety**: Clear boundaries prevent type confusion.
5. **Maintainability**: Fewer layers to maintain.
6. **Core Data Integration**: Direct use of Core Data features.


### ARCHITECTURE

SwiftUI View → ViewModel → Repository → (LocalStore + CloudStore)

Local Repository: Fast, offline cache, saves immediately, supports low-latency UI.

Cloud Repository: Authoritative source of truth, syncs data with other devices and users.

#### LOAD (read-through + background refresh):
UI → ViewModel → UnifiedRepository.fetch → LocalStore (Core Data) → Domain Models → ViewModel → UI

SyncEngine.pull → CloudStore (Cloud Run) → DTO → map→Domain → Core Data upsert → notify → ViewModel → UI

#### SAVE (create/update: optimistic UI + write-behind):
UI → ViewModel → UnifiedRepository.create/update → LocalStore(Core Data) write → Domain Models → ViewModel → UI

UnifiedRepository.enqueue(outbox) → SyncEngine.push → CloudStore(Cloud Run) → ack/version → Core Data upsert → notify → ViewModel → UI

#### DELETE (tombstone + eventual purge):
UI → ViewModel → UnifiedRepository.delete → LocalStore mark deleted(tombstone) → ViewModel → UI

SyncEngine.push(delete) → CloudStore(Cloud Run) → ack → Core Data purge(later) → notify → ViewModel → UI

#### COLD START (no cache → fetch):
UI → ViewModel → UnifiedRepository.fetch → LocalStore miss → (return empty) → ViewModel → UI

SyncEngine.pull → CloudStore(Cloud Run) → DTO → map→Domain → Core Data upsert → notify → ViewModel → UI

### Default Vibe Hydration

- `SystemVibeHydrator` calls `GET /vibes?system_only=true&active_only=true` during splash to keep Core Data in sync with server defaults.
- The hydrator stores the server ETag so the splash screen only re-downloads when the canonical list changes.
- `SplashViewModel` updates the UI status text while seeding; once complete it continues the normal session evaluation flow.
