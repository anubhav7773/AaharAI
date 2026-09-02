# External Integrations

**Analysis Date:** 2026-09-02

## APIs & External Services

**Food analysis backend:**
- Render-hosted FastAPI endpoint is the only configured external service.
  - SDK/Client: `dio` in `mobile/lib/core/network/api_client.dart`
  - Auth: Not detected; requests contain no API token or user identity.
  - Endpoints: `/health`, `/api/v1/scan/barcode/{barcode}`, `/api/v1/scan/vision`, and `/api/v1/scan/street-food`.

**Specified but not implemented in this repository:**
- Supabase/PostgreSQL, Gemini, OpenFoodFacts, Google Play Billing, and AdMob are described in `aahar_ai_docs/Doc_02_Database_Schema_Migrations.md`, `Doc_05_Gemini_Structured_Prompts.md`, `Doc_06_OpenFoodFacts_Integration.md`, and `Doc_09_AdMob_Monetization_SafeFlow.md`; no corresponding client SDK, backend module, schema migration, or platform integration is present.

## Data Storage

**Databases:**
- Not detected in application source. The supplied design specifies Supabase PostgreSQL, but no connection or persistence layer exists.

**File Storage:**
- Local image files are passed to multipart upload by `mobile/lib/core/network/api_client.dart`; durable image storage is not implemented.

**Caching:**
- None detected. `path_provider` is declared but no cache repository is present.

## Authentication & Identity

**Auth Provider:**
- None detected. `mobile/lib/features/auth/presentation/welcome_screen.dart` is a welcome screen, not an authentication flow.

## Monitoring & Observability

**Error Tracking:**
- None detected.

**Logs:**
- Errors are held in Riverpod `AsyncValue` state in `mobile/lib/features/scanner/controllers/scanner_controller.dart`; no structured logging or telemetry is configured.

## CI/CD & Deployment

**Hosting:**
- Mobile client targets Flutter platforms. The hardcoded API points to Render, but backend deployment files are absent.

**CI Pipeline:**
- None detected.

## Environment Configuration

**Required env vars:**
- None declared. The backend URL should be externalized before production.

**Secrets location:**
- No secret files were read or found in the inspected application tree; no secret-management mechanism is detected.

## Webhooks & Callbacks

**Incoming:** None detected.

**Outgoing:** None detected.

---

*Integration audit: 2026-09-02*
