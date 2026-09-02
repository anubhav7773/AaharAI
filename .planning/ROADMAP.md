# Roadmap: AaharAi

## Overview

AaharAi will progress from the existing Flutter UI scaffold to a verified Android-first food-transparency product. The roadmap starts with safe environment injection, then builds the backend contracts and integrations, persistence, mobile wiring, authentication, release compliance, and final deployment verification.

## Phases

### Phase 1: Environment and Configuration Foundation

**Goal:** Backend and mobile have safe, documented, environment-driven configuration without committed secrets.
**Mode:** mvp

**Requirements:** CONF-01, CONF-02, CONF-03

### Phase 2: FastAPI Platform and Contracts

**Goal:** A deployable FastAPI service exposes health/versioning, typed contracts, authentication boundaries, and consistent errors.
**Mode:** mvp

**Requirements:** BACK-01, BACK-02, BACK-03

### Phase 3: Food Intelligence Pipelines

**Goal:** Barcode, label vision, and street-food analysis produce compliant typed results using the documented external services.
**Mode:** mvp

**Requirements:** FOOD-01, FOOD-02, FOOD-03, FOOD-04

### Phase 4: Supabase Schema and Cache

**Goal:** Profiles and global food-cache data are persisted with deduplication, indexes, triggers, and RLS.
**Mode:** mvp

**Requirements:** DATA-01, DATA-02

### Phase 5: Mobile Scan Integration

**Goal:** Existing scanner entry points complete barcode, vision, and street-food requests against the local backend contract with resilient UX.
**Mode:** mvp

**Requirements:** MOB-01, MOB-02

### Phase 6: Authentication and Protected App State

**Goal:** Firebase Google Sign-In protects app routes and backend requests, with user identity available to mobile state.
**Mode:** mvp

**Requirements:** MOB-03, REL-01

### Phase 7: Diary and History Persistence

**Goal:** Users can log analyzed foods, calculate serving macros, and retrieve their authenticated history.
**Mode:** mvp

**Requirements:** DATA-03

### Phase 8: Compliance, Monetization, and Quality

**Goal:** Android policy surfaces, disclaimers, monetization safeguards, and automated coverage are ready for release review.
**Mode:** mvp

**Requirements:** REL-02, REL-03

### Phase 9: Zero-Cost Deployment and Release Verification

**Goal:** Backend and mobile setup is reproducible on the documented free-tier services and verified end-to-end.
**Mode:** mvp

**Requirements:** REL-04

## Phase Dependencies

```text
Phase 1
  -> Phase 2 -> Phase 3
  -> Phase 4
Phase 2 + Phase 3 + Phase 4 -> Phase 5
Phase 5 -> Phase 6 -> Phase 7
Phase 3 + Phase 5 + Phase 6 + Phase 7 -> Phase 8 -> Phase 9
```

## Progress

| Phase | Status | Requirements |
|-------|--------|--------------|
| 1. Environment and Configuration Foundation | Not started | 0/3 |
| 2. FastAPI Platform and Contracts | Not started | 0/3 |
| 3. Food Intelligence Pipelines | Not started | 0/4 |
| 4. Supabase Schema and Cache | Not started | 0/2 |
| 5. Mobile Scan Integration | Not started | 0/2 |
| 6. Authentication and Protected App State | Not started | 0/2 |
| 7. Diary and History Persistence | Not started | 0/1 |
| 8. Compliance, Monetization, and Quality | Not started | 0/2 |
| 9. Zero-Cost Deployment and Release Verification | Not started | 0/1 |

---
*Roadmap created: 2026-09-02*
