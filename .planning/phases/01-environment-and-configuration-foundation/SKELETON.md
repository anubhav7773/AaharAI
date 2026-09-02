# Walking Skeleton — AaharAI

**Phase:** 1
**Generated:** 2026-09-02

## Capability Proven End-to-End

> A developer can start the backend with validated local settings and build the mobile app with explicitly supplied public configuration, without committing deployment secrets.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | FastAPI/Python 3.11+ backend configuration boundary and existing Flutter/Dart 3.3+ client | Matches the supplied architecture and existing mobile scaffold. |
| Data layer | No persistence in this phase; Supabase values are configuration inputs only | Database schema and cache belong to later phases. |
| Auth | No authentication in this phase | Firebase token verification is Phase 2/6 scope. |
| Deployment target | Local backend launch from `backend` plus Flutter `--dart-define` build/test commands | Proves the configuration contract before Render deployment in Phase 9. |
| Directory layout | Backend settings in `backend/app/core/config.py`; mobile configuration in `mobile/lib/core/config/app_env.dart` | Establishes the documented clean-architecture boundaries for later consumers. |

## Stack Touched in Phase 1

- [x] Project scaffold (backend package/dependency manifest and existing Flutter scaffold)
- [ ] Routing — not in this phase
- [ ] Database — not in this phase
- [x] UI — app bootstrap consumes validated configuration; no new screen is required
- [x] Deployment — documented local full-stack/configuration run commands

## Out of Scope (Deferred to Later Slices)

- FastAPI health and versioned routers
- Firebase authentication and protected requests
- Supabase schema, RLS, cache reads, and writes
- Gemini, Open Food Facts, vision, diary, and release deployment behavior

## Subsequent Slice Plan

Each later phase adds a vertical slice on top of these configuration boundaries:

- Phase 2: FastAPI health, versioned routes, auth verification, and typed contracts
- Phase 3: Supabase migrations, RLS, and cache persistence
- Phase 4: Barcode, vision, and street-food intelligence pipelines
- Phase 5: Mobile scan requests, responses, retries, and failure states
- Phase 6: Google identity and protected mobile state
- Phase 7: Diary and history persistence
- Phase 8: Compliance, monetization, and automated quality
- Phase 9: Reproducible zero-cost deployment
