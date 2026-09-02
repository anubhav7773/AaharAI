# Requirements: AaharAi

**Defined:** 2026-09-02  
**Core Value:** Users can scan or describe a food and receive a trustworthy, plain-language explanation of what it contains and how it was prepared.

## v1 Requirements

### Environment and Configuration

- [ ] **CONF-01**: Backend loads required Gemini and Supabase settings from `backend/.env` through Pydantic Settings and fails loudly when required values are missing.
- [ ] **CONF-02**: Backend `.env` and mobile `.env` files are ignored by git and contain safe placeholder configuration templates.
- [ ] **CONF-03**: Mobile API and Supabase public settings are supplied through `--dart-define` with documented defaults and validation.

### Backend Platform

- [ ] **BACK-01**: FastAPI exposes a health endpoint and versioned API router suitable for Render deployment.
- [ ] **BACK-02**: Backend verifies Firebase identity tokens and applies bounded request validation and error handling.
- [ ] **BACK-03**: Backend uses typed Pydantic response contracts for barcode, vision, and street-food analysis.

### Food Intelligence

- [ ] **FOOD-01**: Barcode scans use cache, Open Food Facts lookup, and Gemini fallback in the documented order.
- [ ] **FOOD-02**: Vision scans process compressed ingredient-label images in memory and return ingredient, additive, allergen, and nutrient explanations.
- [ ] **FOOD-03**: Street-food analysis estimates nutrients using IFCT baselines and surfaces preparation insights.
- [ ] **FOOD-04**: Outputs enforce FSSAI allergen/INS rules and the educational no-medical-claims boundary.

### Data and Diary

- [ ] **DATA-01**: Supabase migrations create profiles, food cache, and food logs with indexes, triggers, and RLS policies.
- [ ] **DATA-02**: Cached analyses are deduplicated and reused to control external API and Gemini quotas.
- [ ] **DATA-03**: Authenticated users can persist diary entries and retrieve date-scoped history with calculated serving macros.

### Mobile Experience

- [ ] **MOB-01**: Mobile scanner sends barcode, vision, and street-food requests to the configured backend and renders typed results.
- [ ] **MOB-02**: Mobile handles cold starts, timeout/retry states, not-found barcodes, malformed responses, and user-visible errors.
- [ ] **MOB-03**: Authentication, protected navigation, profile state, diary state, and history replace demo-only state.

### Release and Quality

- [ ] **REL-01**: Firebase Google Sign-In is configured for the Android package with debug/release signing fingerprints documented.
- [ ] **REL-02**: Privacy policy, disclaimer, AdMob/Play Billing safe flow, and Android release configuration satisfy the product boundary.
- [ ] **REL-03**: Automated tests cover configuration, models, safety filtering, API contracts, persistence, and core scan states.
- [ ] **REL-04**: Backend and mobile can be deployed using the documented zero-cost services with reproducible setup instructions.

## v2 Requirements

### Product Expansion

- **V2-01**: iOS release hardening and App Store delivery.
- **V2-02**: Advanced personalization and dietary recommendation features beyond transparent education.
- **V2-03**: Expanded offline catalog and richer analytics.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Medical diagnosis or treatment advice | Violates the educational product boundary and creates regulatory risk |
| Permanent raw image storage | Conflicts with the zero-raw-image policy and free-tier storage limits |
| Paid AI/data infrastructure | Violates the strict $0.00 deployment budget |
| iOS-first delivery | Android is the initial platform priority |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONF-01 | Phase 1 | Pending |
| CONF-02 | Phase 1 | Pending |
| CONF-03 | Phase 1 | Pending |
| BACK-01 | Phase 2 | Pending |
| BACK-02 | Phase 2 | Pending |
| BACK-03 | Phase 2 | Pending |
| FOOD-01 | Phase 3 | Pending |
| FOOD-02 | Phase 3 | Pending |
| FOOD-03 | Phase 3 | Pending |
| FOOD-04 | Phase 3 | Pending |
| DATA-01 | Phase 4 | Pending |
| DATA-02 | Phase 4 | Pending |
| DATA-03 | Phase 7 | Pending |
| MOB-01 | Phase 5 | Pending |
| MOB-02 | Phase 5 | Pending |
| MOB-03 | Phase 6 | Pending |
| REL-01 | Phase 6 | Pending |
| REL-02 | Phase 8 | Pending |
| REL-03 | Phase 8 | Pending |
| REL-04 | Phase 9 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-09-02*  
*Last updated: 2026-09-02 after initial definition*
