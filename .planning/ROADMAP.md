# Roadmap: AaharAi

## Overview

AaharAi will turn the existing Flutter scanner shell into a verified Android-first
food-transparency product. This fine-grained MVP roadmap follows the documented
vertical boundaries: safe configuration, backend contracts, persistence-backed
food intelligence, mobile scan flows, identity and diary state, then release
compliance and zero-cost deployment. The supplied architecture documents in
`aahar_ai_docs/` are the source of truth for integration order, data contracts,
quota safeguards, safety language, and platform policy.

**Mode:** mvp
**Granularity:** fine
**Research:** skipped by request; architecture docs used instead

## Phases

- [x] **Phase 1: Environment and Configuration Foundation** - Establish validated backend settings and build-time mobile configuration without secrets.
- [ ] **Phase 2: FastAPI Platform and Contracts** - Provide the authenticated, versioned service boundary and typed analysis contracts.
- [ ] **Phase 3: Supabase Schema and Cache** - Persist shared analyses and user foundations with deduplication, indexes, triggers, and RLS.
- [ ] **Phase 4: Food Intelligence Pipelines** - Deliver compliant barcode, label-vision, and street-food analysis through bounded external integrations.
- [ ] **Phase 5: Mobile Scan Integration** - Connect all scanner entry points to the backend and make loading, retry, and failure states useful.
- [ ] **Phase 6: Authentication and Protected App State** - Connect Google identity to protected requests, routes, profiles, and durable mobile state.
- [ ] **Phase 7: Diary and History Persistence** - Let users log scan results, calculate serving macros, and retrieve date-scoped history.
- [ ] **Phase 8: Compliance, Monetization, and Automated Quality** - Make policy surfaces, safe monetization, and core automated verification release-ready.
- [ ] **Phase 9: Zero-Cost Deployment and Release Verification** - Prove reproducible free-tier deployment and the complete scan-to-understanding journey.

## Phase Details

### Phase 1: Environment and Configuration Foundation

**Goal**: Backend and mobile use validated, environment-driven configuration without committed deployment secrets.
**Depends on**: Nothing (first phase)
**Requirements**: CONF-01, CONF-02, CONF-03
**Success Criteria** (what must be TRUE):

  1. Starting the backend with missing required Gemini or Supabase settings fails with a clear configuration error, while valid `backend/.env` values load through Pydantic Settings.
  2. Backend and mobile environment files are ignored by git, and safe placeholder templates explain which values are required without exposing secrets.
  3. A mobile build can select the backend URL and Supabase public settings through `--dart-define`, applies documented defaults where allowed, and rejects invalid required values.

**Plans**: 2/2 plans executed

Plans:

- [x] 01-01-PLAN.md — Establish validated Pydantic backend settings and secret-file hygiene
- [x] 01-02-PLAN.md — Inject and validate mobile build-time configuration

### Phase 2: FastAPI Platform and Contracts

**Goal**: A deployable FastAPI service presents a stable versioned API boundary with authenticated requests, bounded inputs, typed results, and consistent errors.
**Depends on**: Phase 1
**Requirements**: BACK-01, BACK-02, BACK-03
**Success Criteria** (what must be TRUE):

  1. `GET /health` reports service readiness and `/api/v1` registers the documented barcode, vision, street-food, and diary route boundary.
  2. A valid Firebase identity token is accepted for protected requests, while missing or invalid tokens receive a safe authentication error without leaking internals.
  3. Barcode, vision, and street-food responses validate against concrete Pydantic contracts containing typed nutrients, ingredients, allergens, source, and preparation insights.
  4. Invalid barcodes, unsupported or oversized uploads, upstream failures, rate limits, and unexpected exceptions resolve to documented HTTP statuses and user-safe messages.

**Plans**: 2 plans

### Phase 3: Supabase Schema and Cache

**Goal**: The service has safe, quota-conscious persistence for profiles and globally reusable food analyses.
**Depends on**: Phase 1; may proceed in parallel with Phase 2 after configuration is established
**Requirements**: DATA-01, DATA-02
**Success Criteria** (what must be TRUE):

  1. Applying the documented migration creates `profiles`, `food_cache`, and `food_logs` with the required enums, constraints, indexes, timestamps, triggers, and profile-on-signup behavior.
  2. A signed-in user can read and update only their own profile and can never read or modify another user's diary data under the RLS policies.
  3. Authenticated clients can read shared cached food results while cache writes and hit-count updates remain controlled by the backend/service role.
  4. Repeating a barcode or equivalent vision signature returns the existing cached analysis and avoids another Open Food Facts or Gemini call.

**Plans**: TBD

### Phase 4: Food Intelligence Pipelines

**Goal**: Users receive trustworthy, plain-language food explanations from the documented barcode, label-image, and street-food workflows.
**Depends on**: Phase 2 and Phase 3
**Requirements**: FOOD-01, FOOD-02, FOOD-03, FOOD-04
**Success Criteria** (what must be TRUE):

  1. A barcode request checks cache first, then queries Open Food Facts with the required projected fields and User-Agent/rate-limit safeguards, sends found ingredients to Gemini only when needed, caches the result, and returns a typed explanation.
  2. A label image is bounded and processed transiently in memory; the result contains OCR-derived ingredients in order, nutrients per 100g, additive explanations, and detected allergens without persisting the raw image.
  3. A street-food request estimates nutrients from the documented IFCT 2017 baselines and explains preparation factors such as refined starch, sodium/MSG, steaming, or oil reuse in an accessible tone.
  4. Every analysis applies the documented FSSAI allergen and INS classifications, structured Gemini output validation, and the educational no-medical-claims vocabulary boundary.

**Plans**: TBD

### Phase 5: Mobile Scan Integration

**Goal**: Android users can complete barcode, label-image, and street-food scans against the typed backend and understand what happens when the network or product lookup fails.
**Depends on**: Phase 4
**Requirements**: MOB-01, MOB-02
**Success Criteria** (what must be TRUE):

  1. Each existing scanner entry point sends the correct typed request to the configured backend and renders the returned product, nutrients, ingredients, allergens, safety badges, and preparation insights.
  2. Opening the camera initiates the documented non-blocking health warm-up, and transient timeouts, cold starts, 429s, and 502s show actionable retry feedback rather than silent failure.
  3. A not-found barcode offers the documented back-label photo fallback, while malformed responses and unsupported images produce a safe user-visible error.
  4. Compressed label images stay within the documented dimensions and quality/payload bounds before upload, with raw camera data discarded after processing.

**Plans**: TBD
**UI hint**: yes

### Phase 6: Authentication and Protected App State

**Goal**: Users can sign in with Google and move through a protected app whose requests and profile state are tied to their Firebase identity.
**Depends on**: Phase 2 and Phase 5
**Requirements**: MOB-03, REL-01
**Success Criteria** (what must be TRUE):

  1. Google Sign-In works for the Android package in debug and release configurations using documented signing fingerprints, and the resulting Firebase session can be restored or ended.
  2. Authenticated mobile requests carry the Firebase identity token and protected routes redirect unauthenticated users to the welcome/sign-in screen.
  3. A signed-in user sees and can update their own profile state, while sign-out clears protected client state and prevents further protected requests.
  4. Android Firebase configuration and package/signing setup are reproducible from the documented project values without embedding private credentials in source.

**Plans**: TBD
**UI hint**: yes

### Phase 7: Diary and History Persistence

**Goal**: Users can turn an analysis into a durable, date-scoped diary and see accurate serving-based macro totals across sessions.
**Depends on**: Phase 3, Phase 5, and Phase 6
**Requirements**: DATA-03
**Success Criteria** (what must be TRUE):

  1. From an analysis result, a signed-in user can choose a serving quantity and meal type and save the entry to their own diary.
  2. Diary totals calculate calories, protein, carbohydrates, and fat from the selected serving size rather than demo values.
  3. Users can select a date and retrieve only their own history, with empty and loading states that remain understandable.
  4. Diary and history survive app restart and reflect additions, edits, or deletions through the authenticated persistence boundary.

**Plans**: TBD
**UI hint**: yes

### Phase 8: Compliance, Monetization, and Automated Quality

**Goal**: The Android product presents required educational boundaries, uses non-intrusive monetization, and has automated checks for the core safety and persistence behavior.
**Depends on**: Phase 4, Phase 5, Phase 6, and Phase 7
**Requirements**: REL-02, REL-03
**Success Criteria** (what must be TRUE):

  1. Onboarding, every analysis result, settings/about, and the store-facing copy expose the required non-medical and educational disclaimers, and prohibited claims are filtered from displayed AI text.
  2. The public privacy policy describes food images, AI processing, Open Food Facts, diary data, retention/deletion, and account deletion; Android permissions are limited to the documented needs.
  3. Free-tier banners appear only in diary/history and interstitials can occur only after result dismissal with the documented frequency cap; Pro purchase/restore states do not block scan results.
  4. Automated tests cover configuration validation, typed model parsing, safety filtering, API contracts, persistence/RLS behavior, and core scan/loading/error/success states.

**Plans**: TBD
**UI hint**: yes

### Phase 9: Zero-Cost Deployment and Release Verification

**Goal**: The backend and Android client can be deployed reproducibly on the documented free services and pass a complete production-shaped verification run within the $0 budget.
**Depends on**: Phase 8
**Requirements**: REL-04
**Success Criteria** (what must be TRUE):

  1. A fresh setup can deploy the FastAPI service to Render, apply Supabase migrations, configure Firebase, and build the Android app using documented steps and environment inputs only.
  2. The deployed health endpoint, authenticated API, Supabase cache/RLS, Open Food Facts fallback, Gemini analysis, and mobile configuration operate together without hardcoded deployment secrets.
  3. A tester can complete barcode hit/miss-to-photo fallback, vision, street-food, sign-in, log-to-diary, and date-scoped history flows against the deployed services.
  4. Verification records confirm free-tier safeguards: cache reuse, OFF throttling, Gemini backoff, Render warm-up, transient image handling, and no paid infrastructure dependency.

**Plans**: TBD

## Phase Dependencies

```text
Phase 1
  ├─> Phase 2
  └─> Phase 3
Phase 2 + Phase 3
  └─> Phase 4
Phase 4
  └─> Phase 5
Phase 2 + Phase 5
  └─> Phase 6
Phase 3 + Phase 5 + Phase 6
  └─> Phase 7
Phase 4 + Phase 5 + Phase 6 + Phase 7
  └─> Phase 8
Phase 8
  └─> Phase 9
```

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Environment and Configuration Foundation | 2/2 | Complete | 2026-09-02 |
| 2. FastAPI Platform and Contracts | 0/TBD | Not started | - |
| 3. Supabase Schema and Cache | 0/TBD | Not started | - |
| 4. Food Intelligence Pipelines | 0/TBD | Not started | - |
| 5. Mobile Scan Integration | 0/TBD | Not started | - |
| 6. Authentication and Protected App State | 0/TBD | Not started | - |
| 7. Diary and History Persistence | 0/TBD | Not started | - |
| 8. Compliance, Monetization, and Automated Quality | 0/TBD | Not started | - |
| 9. Zero-Cost Deployment and Release Verification | 0/TBD | Not started | - |

## Requirement Coverage

All 20 v1 requirements map to exactly one phase:

| Requirement | Phase |
|-------------|-------|
| CONF-01, CONF-02, CONF-03 | Phase 1 |
| BACK-01, BACK-02, BACK-03 | Phase 2 |
| DATA-01, DATA-02 | Phase 3 |
| FOOD-01, FOOD-02, FOOD-03, FOOD-04 | Phase 4 |
| MOB-01, MOB-02 | Phase 5 |
| MOB-03, REL-01 | Phase 6 |
| DATA-03 | Phase 7 |
| REL-02, REL-03 | Phase 8 |
| REL-04 | Phase 9 |

**Coverage:** 20/20 v1 requirements mapped; 0 orphaned; 0 duplicated.

---
*Roadmap finalized: 2026-09-02*
