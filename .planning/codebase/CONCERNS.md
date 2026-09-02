# Codebase Concerns

**Analysis Date:** 2026-09-02

## Tech Debt

**Missing backend and persistence implementation:**
- Issue: Repository contains a Flutter client only, while supplied docs require FastAPI, Supabase migrations/RLS, Gemini prompts, FSSAI/IFCT logic, and OpenFoodFacts integration.
- Files: `mobile/lib/core/network/api_client.dart`, `aahar_ai_docs/Doc_02_Database_Schema_Migrations.md`, `aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md`.
- Impact: Remote calls depend on an unversioned external service; diary, accounts, quotas, and history cannot work end-to-end.
- Fix approach: Add a separately deployable backend and migration tree, define versioned DTOs, and connect repositories to durable/authenticated storage.

**Hardcoded/demo product state:**
- Issue: Street-food entries, diary meals, calorie target, and subscription tiers are static in widgets.
- Files: `mobile/lib/features/street_food/presentation/street_food_screen.dart`, `mobile/lib/features/diary/presentation/daily_diary_screen.dart`, `mobile/lib/features/subscription/presentation/paywall_sheet.dart`.
- Impact: UI can look complete while user data, search, billing, and entitlements are nonfunctional.
- Fix approach: Replace lists with repositories/providers backed by the documented API and billing adapters.

**Incomplete integration configuration:**
- Issue: Base URL is hardcoded and no auth, environment, CI, or release configuration is detected.
- Files: `mobile/lib/core/network/api_client.dart`, `mobile/pubspec.yaml`.
- Impact: Unsafe environment switching and difficult staging/production deployment.
- Fix approach: Inject build-time configuration and add CI validation without embedding secrets.

## Known Bugs

**Silent failure paths:**
- Symptoms: Server warm-up and retry failures are swallowed; callers receive only nullable results or generic async errors.
- Files: `mobile/lib/core/network/api_client.dart`, `mobile/lib/features/scanner/controllers/scanner_controller.dart`.
- Trigger: Render cold start or malformed/non-2xx response.
- Workaround: None visible to the user beyond controller error state.

## Security Considerations

**Untrusted AI/API text:**
- Risk: Regex replacement is a narrow client-side compliance filter and is not a substitute for server-side prompt/output validation.
- Files: `mobile/lib/core/utils/safety_filter.dart`, `mobile/lib/features/analysis/models/food_analysis_model.dart`.
- Current mitigation: Sanitization on selected response fields and disclaimer widgets.
- Recommendations: Validate typed server responses, enforce policy at the backend, and test bypass variants.

**Transport and identity:**
- Risk: No authentication, request signing, quota enforcement, or explicit network-security policy is visible in the client.
- Files: `mobile/lib/core/network/api_client.dart`, `mobile/android/app/src/main/AndroidManifest.xml`.
- Current mitigation: HTTPS base URL.
- Recommendations: Add authenticated sessions, server-side rate limits, safe upload limits, and environment-controlled endpoints.

## Performance Bottlenecks

**Remote scan latency:**
- Problem: Vision/Gemini work is remote and receives a 25-second timeout plus one retry.
- Files: `mobile/lib/core/network/api_client.dart`.
- Cause: Render cold starts and AI inference are on the request path.
- Improvement path: Explicit job/progress states, server warm-up strategy, bounded retries, and cached barcode results.

## Fragile Areas

**API payload coupling:**
- Files: `mobile/lib/features/analysis/models/food_analysis_model.dart`, `mobile/lib/core/network/api_client.dart`.
- Why fragile: Untyped maps and permissive zero/empty defaults can hide contract drift.
- Safe modification: Introduce DTO validation and contract tests before changing backend response fields.
- Test coverage: No model or API tests.

**Large presentation widgets:**
- Files: `mobile/lib/features/analysis/presentation/food_analysis_screen.dart`, `mobile/lib/features/scanner/presentation/universal_scanner_screen.dart`, `mobile/lib/features/street_food/presentation/street_food_screen.dart`.
- Why fragile: UI, local state, sample data, and side effects coexist in large files.
- Safe modification: Extract view models/repositories and add widget tests around scan/loading/error/success states.
- Test coverage: Only app smoke test.

## Scaling Limits

**In-memory user experience:**
- Current capacity: Static demo data only.
- Limit: No multi-user or cross-session state.
- Scaling path: Authenticated persistence, repository interfaces, local cache, and synchronization.

## Dependencies at Risk

**External Render backend:**
- Risk: Client depends on a URL with no backend code or health contract in this repository.
- Impact: Deployment/API drift can break all scan features.
- Migration plan: Version and deploy the documented FastAPI service, then inject endpoint configuration.

## Missing Critical Features

**Documented platform services:**
- Problem: Supabase, Gemini, OpenFoodFacts, AdMob/Billing, auth, quotas, and backend endpoints are specified but not implemented locally.
- Blocks: Production analysis, history/diary persistence, monetization, and zero-cost deployment verification.

**Documentation completeness:**
- Problem: Root `README.md` is only “AI powered food app”; `mobile/README.md` remains the Flutter starter text.
- Blocks: Reliable setup, architecture onboarding, API contract discovery, and release operations.

## Test Coverage Gaps

**Core flows:**
- What's not tested: Barcode/image/street-food requests, JSON parsing, retry behavior, safety filtering, routing, and screen states.
- Files: `mobile/lib/core/network/api_client.dart`, `mobile/lib/features/scanner/controllers/scanner_controller.dart`, `mobile/lib/features/analysis/models/food_analysis_model.dart`, `mobile/lib/core/utils/safety_filter.dart`.
- Risk: Contract and compliance regressions go unnoticed.
- Priority: High.

---

*Concerns audit: 2026-09-02*
