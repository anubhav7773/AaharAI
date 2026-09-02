<!-- refreshed: 2026-09-02 -->
# Architecture

**Analysis Date:** 2026-09-02

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│ Flutter presentation                                       │
│ `mobile/lib/features/*/presentation/`                       │
│ Welcome, scanner, analysis, street food, diary, paywall    │
└───────────────┬───────────────────────┬────────────────────┘
                │ Riverpod/go_router   │ local sample state
                ▼                       ▼
┌──────────────────────────────┐  ┌──────────────────────────┐
│ App coordination              │  │ Shared/core utilities    │
│ `main.dart`, `app_router.dart`│  │ theme, safety, compression│
└───────────────┬──────────────┘  └──────────────────────────┘
                ▼
┌─────────────────────────────────────────────────────────────┐
│ Remote HTTP boundary                                         │
│ `mobile/lib/core/network/api_client.dart`                    │
│ Render-hosted `/api/v1/scan/*` (backend not in repository)   │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Application bootstrap | Provider scope, theme, router, system UI | `mobile/lib/main.dart` |
| Routing shell | Welcome, tab shell, analysis, subscription routes | `mobile/lib/core/router/app_router.dart` |
| Scanner state | Calls scan APIs and maps responses to async state | `mobile/lib/features/scanner/controllers/scanner_controller.dart` |
| API client | Barcode, vision upload, street-food HTTP calls and retry | `mobile/lib/core/network/api_client.dart` |
| Response model | Normalizes nutrients, ingredients, allergens, and safety categories | `mobile/lib/features/analysis/models/food_analysis_model.dart` |
| Feature screens | Render flows and mostly local/sample UI state | `mobile/lib/features/*/presentation/` |

## Pattern Overview

**Overall:** Feature-oriented Flutter UI with a thin service boundary.

**Key Characteristics:**
- Features are grouped by business area, with shared widgets in `mobile/lib/shared/widgets/`.
- Riverpod is used for API client injection and scanner state, not as a complete application data layer.
- Navigation uses a `ShellRoute` for scanner, street food, and diary.
- Backend/domain processing is assumed to be remote and is not present in this repository.

## Layers

**Presentation:**
- Purpose: Render screens and collect user input.
- Location: `mobile/lib/features/*/presentation/`
- Contains: Stateful/stateless widgets, local lists, navigation actions.
- Depends on: Theme, shared widgets, scanner controller/model.
- Used by: `mobile/lib/core/router/app_router.dart`.

**State and integration:**
- Purpose: Coordinate scan requests and parse responses.
- Location: `mobile/lib/features/scanner/controllers/`, `mobile/lib/core/network/`
- Contains: `StateNotifier`, `ApiClient`, Dio retry interceptor.
- Depends on: Remote Render API and analysis models.
- Used by: scanner UI.

**Shared/core:**
- Purpose: Cross-feature styling, compliance text filtering, image helper, reusable cards.
- Location: `mobile/lib/core/` and `mobile/lib/shared/`.

## Data Flow

### Primary Scan Path

1. `UniversalScannerScreen` captures a barcode or image (`mobile/lib/features/scanner/presentation/universal_scanner_screen.dart`).
2. `ScannerController` sets loading state and invokes the matching `ApiClient` method (`mobile/lib/features/scanner/controllers/scanner_controller.dart`).
3. `ApiClient` calls Render `/api/v1/scan/*` and retries timeout/503/504 once (`mobile/lib/core/network/api_client.dart`).
4. `FoodAnalysisResponse.fromJson` normalizes payload data and sanitizes text (`mobile/lib/features/analysis/models/food_analysis_model.dart`).
5. The screen navigates to `/analysis` with response data through `mobile/lib/core/router/app_router.dart`.

### Local Demo Flows

1. Street-food catalogue uses `_sampleStreetFoods` in `mobile/lib/features/street_food/presentation/street_food_screen.dart`.
2. Diary totals use an in-memory `_meals` list in `mobile/lib/features/diary/presentation/daily_diary_screen.dart`.
3. Subscription displays static tier data in `mobile/lib/features/subscription/presentation/paywall_sheet.dart`.

**State Management:** Widget-local state for demo/catalogue screens; Riverpod `AsyncValue` only for scanner operations; no persistence or authenticated user state.

## Key Abstractions

**FoodAnalysisResponse:**
- Purpose: Common UI payload for barcode, vision, and street-food results.
- Examples: `mobile/lib/features/analysis/models/food_analysis_model.dart`.
- Pattern: Defensive JSON parsing with aliases and defaults.

**HealthClaimFilter:**
- Purpose: Replace prohibited medical wording and expose required disclaimers.
- Examples: `mobile/lib/core/utils/safety_filter.dart`.
- Pattern: Static regex sanitizer plus constants.

## Entry Points

**Flutter entry point:**
- Location: `mobile/lib/main.dart`
- Triggers: Platform launcher.
- Responsibilities: Initialize Flutter, ProviderScope, theme, and router.

**Remote API entry point:**
- Location: `mobile/lib/core/network/api_client.dart`
- Triggers: Scanner UI actions.
- Responsibilities: HTTP requests to the externally hosted backend.

## Architectural Constraints

- **Threading:** Flutter UI isolate; no explicit worker/isolate architecture detected.
- **Global state:** Router navigator keys and an API client provider are module-level in `mobile/lib/core/router/app_router.dart` and `mobile/lib/core/network/api_client.dart`.
- **Circular imports:** None detected in inspected imports.
- **Backend boundary:** The client assumes a separate FastAPI service and exact response shapes, but that service is not versioned here.

## Anti-Patterns

### Demo data presented as product state

**What happens:** Diary and street-food features render hardcoded collections in `mobile/lib/features/diary/presentation/daily_diary_screen.dart` and `mobile/lib/features/street_food/presentation/street_food_screen.dart`.
**Why it's wrong:** User data, search results, and nutrition history cannot persist or reflect a backend.
**Do this instead:** Introduce repositories and authenticated persistence matching the supplied schema before treating these screens as production flows.

### Transport configuration embedded in source

**What happens:** `ApiClient.baseUrl` is a compile-time constant in `mobile/lib/core/network/api_client.dart`.
**Why it's wrong:** Environments cannot be switched safely and deployment changes require source edits.
**Do this instead:** Inject typed configuration at app startup.

## Error Handling

**Strategy:** Catch scan exceptions, expose `AsyncValue.error`, and let UI decide presentation; Dio retries selected transient failures once.

**Patterns:**
- `ScannerController` returns nullable results after recording errors.
- JSON parsing defaults missing fields to empty/zero values.
- `warmUpServer` intentionally ignores failures.

## Cross-Cutting Concerns

**Logging:** None beyond framework behavior.
**Validation:** Payload normalization and a client-side claim regex; no request/schema validation layer.
**Authentication:** Not implemented.

---

*Architecture analysis: 2026-09-02*
