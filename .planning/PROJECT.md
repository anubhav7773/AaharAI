# AaharAi

## What This Is

AaharAi is an Android-first Flutter app and FastAPI service that turns Indian packaged-food labels, barcode products, and unpacked street foods into understandable nutritional intelligence. It is for everyday consumers who want plain-language ingredient, additive, allergen, and nutrient explanations without medical claims.

## Core Value

Users can scan or describe a food and receive a trustworthy, plain-language explanation of what it contains and how it was prepared.

## Business Context

- **Customer**: Indian consumers using the free mobile app
- **Revenue model**: Free tier with non-intrusive AdMob ads and a future Pro subscription
- **Success metric**: A complete scan-to-understanding flow that users can repeat reliably
- **Strategy notes**: Product and architecture details are documented in `aahar_ai_docs/`

## Requirements

### Validated

- ✓ Flutter mobile shell with Material 3 theme, Riverpod state management, and GoRouter navigation — existing
- ✓ Scanner UI supports barcode, label-image, and street-food entry points — existing
- ✓ Food analysis UI renders nutrients, ingredients, allergens, safety badges, and disclaimers — existing
- ✓ Dio API client and defensive food-analysis model exist at the mobile API boundary — existing

### Active

- [ ] Backend environment configuration loads required Gemini and Supabase settings through Pydantic Settings.
- [ ] Mobile runtime configuration is injected through `--dart-define` without hardcoded deployment secrets.
- [ ] FastAPI backend provides authenticated, versioned scan and health endpoints.
- [ ] Gemini, Open Food Facts, Supabase cache, FSSAI rules, and IFCT-based street-food analysis work as one bounded service.
- [ ] Supabase schema and RLS persist profiles, food-cache results, and diary logs safely.
- [ ] Firebase Google authentication connects mobile sessions to protected backend requests.
- [ ] Barcode, vision, and street-food flows are wired end-to-end with typed contracts and useful error states.
- [ ] Diary/history persistence and macro calculations replace current demo state.
- [ ] Android release configuration, privacy disclosures, monetization, and zero-cost deployment are production-ready.
- [ ] Core scan, parsing, compliance, and persistence behavior has automated verification.

### Out of Scope

- Medical diagnosis, treatment, disease prevention, or therapeutic recommendations — outside the educational product boundary.
- Storing raw food images permanently — the architecture requires transient in-memory processing.
- Paid infrastructure or proprietary nutrition datasets for v1 — the project has a strict zero-budget constraint.
- iOS-first release work — Android is the initial release target.

## Context

The repository is a brownfield Flutter scaffold with product specifications in `aahar_ai_docs/` and design assets in `design_assets/`. The mobile UI and remote API boundary exist, but the backend, persistence, authentication, environment injection, CI/release configuration, and most automated tests are missing. Existing implementation findings are recorded in `.planning/codebase/`.

The documented architecture uses Flutter/Dart 3.3+, FastAPI/Python 3.11+, Supabase PostgreSQL with RLS, Firebase Auth, Gemini 2.5 Flash, Open Food Facts, Render Free Tier, Riverpod, GoRouter, Dio, and an Android-first delivery model.

## Constraints

- **Budget**: $0.00 operational target — use free tiers and quota safeguards.
- **Security**: Backend-only Gemini and Supabase service-role secrets; mobile receives only public/anonymous client credentials.
- **Compliance**: Explanations must be educational and neutral, recognize FSSAI allergens and INS additives, and avoid prohibited medical language.
- **Data handling**: Raw camera images remain in memory and are discarded after analysis.
- **Compatibility**: Flutter SDK/Dart >=3.3.0, Python 3.11+, FastAPI 0.110+.
- **External limits**: Open Food Facts rate limits, Gemini free-tier quotas, Supabase 500 MB quota, and Render cold starts must be handled explicitly.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Android-first Flutter client | One cross-platform codebase while prioritizing the initial release platform | — Pending |
| FastAPI backend owns AI and administrative integrations | Keeps service-role/API secrets off the client and centralizes policy enforcement | — Pending |
| Supabase cache before Gemini/Open Food Facts calls | Reduces latency, duplicate work, and free-tier usage | — Pending |
| Build-time mobile configuration via `--dart-define` | Allows local, staging, and production endpoints without source edits or embedded secrets | — Pending |
| Map the existing brownfield codebase before roadmap creation | Separates existing UI capabilities from missing production infrastructure | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition**:
1. Requirements invalidated? Move to Out of Scope with reason.
2. Requirements validated? Move to Validated with phase reference.
3. New requirements emerged? Add to Active.
4. Decisions to log? Add to Key Decisions.
5. Confirm that "What This Is" still describes the product.

**After each milestone**:
1. Review all sections and the Core Value.
2. Audit Out of Scope reasons.
3. Update Context with implementation and user evidence.

---
*Last updated: 2026-09-02 after project initialization*
