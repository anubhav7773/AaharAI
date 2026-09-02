# Codebase Structure

**Analysis Date:** 2026-09-02

## Directory Layout

```text
AaharAI/
├── aahar_ai_docs/          # Supplied product, backend, domain, UX, and policy specifications
├── design_assets/           # Design tokens and visual assets
├── mobile/
│   ├── lib/core/            # Network, routing, theme, utilities
│   ├── lib/features/        # Auth, scanner, analysis, street food, diary, subscription
│   ├── lib/shared/widgets/  # Reusable safety/disclaimer/nutrient cards
│   ├── test/                # Flutter tests
│   ├── assets/              # App icons/assets
│   └── android/, ios/, web/ # Flutter platform hosts
└── README.md                # Minimal repository description
```

## Directory Purposes

**`mobile/lib/core/`:**
- Purpose: Application-wide infrastructure.
- Key files: `mobile/lib/core/network/api_client.dart`, `mobile/lib/core/router/app_router.dart`, `mobile/lib/core/theme/app_theme.dart`.

**`mobile/lib/features/`:**
- Purpose: Feature-first product modules.
- Contains: Presentation screens, scanner controller, analysis model.
- Key files: `mobile/lib/features/scanner/`, `mobile/lib/features/analysis/`.

**`mobile/lib/shared/widgets/`:**
- Purpose: Reusable UI and compliance components.
- Key files: `health_disclaimer_footer.dart`, `safety_badge.dart`, `allergen_alert_card.dart`, `macro_pill_card.dart`.

**`aahar_ai_docs/`:**
- Purpose: Architecture source of truth for planned FastAPI, Supabase, Gemini, OpenFoodFacts, UX, state, monetization, and policy behavior.

## Key File Locations

**Entry Points:**
- `mobile/lib/main.dart`: Flutter application bootstrap.
- `mobile/android/app/src/main/AndroidManifest.xml`: Android launcher host.

**Configuration:**
- `mobile/pubspec.yaml`: dependencies, assets, SDK constraint.
- `mobile/analysis_options.yaml`: lint/analyzer configuration.
- `mobile/android/app/build.gradle.kts`: Android build configuration.

**Core Logic:**
- `mobile/lib/core/network/api_client.dart`: remote API boundary.
- `mobile/lib/features/scanner/controllers/scanner_controller.dart`: scan orchestration.
- `mobile/lib/features/analysis/models/food_analysis_model.dart`: API-to-UI model.

**Testing:**
- `mobile/test/widget_test.dart`: only detected test.

## Naming Conventions

**Files:**
- Lowercase snake_case Dart files, e.g. `food_analysis_screen.dart`.
- Feature folders use lowercase names; presentation/controller/model subfolders are explicit.

**Directories:**
- `core`, `features`, and `shared` are top-level Dart organization boundaries.

## Where to Add New Code

**New Feature:**
- Primary code: `mobile/lib/features/<feature>/presentation/`, with `models/`, `controllers/`, and repositories added as needed.
- Tests: co-located under `mobile/test/` using feature-oriented names.

**New Component/Module:**
- Implementation: `mobile/lib/shared/widgets/` only for genuinely cross-feature widgets; otherwise keep it in the owning feature.

**Utilities:**
- Shared helpers: `mobile/lib/core/utils/`; infrastructure clients belong under `mobile/lib/core/`.

**Backend and persistence required by the supplied architecture:**
- No current directory exists. Add a separately organized backend/database tree rather than placing server logic in `mobile/lib/`; update integration/config documentation with the boundary.

## Special Directories

**`mobile/build/` and `mobile/.dart_tool/`:**
- Purpose: Flutter-generated artifacts.
- Generated: Yes. Treat as non-source and do not add application logic.

**`design_assets/`:**
- Purpose: Design references consumed by the UI.
- Generated: Not detected; inspect before replacing.

---

*Structure analysis: 2026-09-02*
