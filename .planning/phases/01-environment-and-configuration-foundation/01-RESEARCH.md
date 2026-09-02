# Phase 1: Environment and Configuration Foundation - Research

**Researched:** 2026-09-02  
**Domain:** Python/FastAPI environment configuration and Flutter build-time configuration  
**Confidence:** HIGH for repository structure and requirements; MEDIUM for library behavior; LOW for unresolved naming choices

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONF-01 | Backend loads required Gemini and Supabase settings from `backend/.env` through Pydantic Settings and fails loudly when required values are missing. [VERIFIED: .planning/REQUIREMENTS.md:8-12] | Add a typed settings module under the documented `backend/app/core/config.py`; use required fields, `.env` loading, and a startup/import test. |
| CONF-02 | Backend `.env` and mobile `.env` files are ignored by git and contain safe placeholder configuration templates. [VERIFIED: .planning/REQUIREMENTS.md:8-12] | Add `backend/.env.example`, `mobile/.env.example`, and explicit ignore rules; never commit real values. |
| CONF-03 | Mobile API and Supabase public settings are supplied through `--dart-define` with documented defaults and validation. [VERIFIED: .planning/REQUIREMENTS.md:8-12] | Add a const `AppEnv` value object and replace the hardcoded URL in `mobile/lib/core/network/api_client.dart`. |

## Summary

The phase is a foundation-only change: the backend directory does not exist, while the Flutter client currently hardcodes `https://aaharai-backend.onrender.com` in `mobile/lib/core/network/api_client.dart:7-15`. [VERIFIED: .planning/STATE.md:27-29; mobile/lib/core/network/api_client.dart:7-15] The supplied architecture explicitly assigns environment variables to `backend/app/core/config.py` and requires a Python 3.11+ FastAPI service. [VERIFIED: aahar_ai_docs/Doc_01_Product_Architecture_Rules.md:60-88; aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md:3-11] Use Pydantic Settings v2 for backend configuration and Dart compile-time environment declarations for mobile; do not add a mobile dotenv runtime dependency.

The safest boundary is: Gemini API key and Supabase service-role key exist only in backend settings; mobile receives only a backend URL and Supabase public/anonymous values. [VERIFIED: .planning/PROJECT.md:53-60] A `.env.example` is documentation/template only, while ignored `.env` files are developer-local inputs. Flutter `String.fromEnvironment` values are compile-time declarations, so validation must happen in `AppEnv` before constructing the API client. [CITED: https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html]

**Primary recommendation:** Create a small typed backend settings module with `pydantic-settings`, a const Flutter `AppEnv` sourced from `--dart-define`, explicit ignore/template files, and focused tests before Phase 2 consumes either configuration.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Backend secret loading and required-value validation | API / Backend | — | Gemini and Supabase service-role secrets must stay server-side. [VERIFIED: .planning/PROJECT.md:53-60] |
| Mobile endpoint/public Supabase configuration | Browser / Client | API / Backend | Build-time Dart values select the client’s backend and public project settings; they must not contain server secrets. [VERIFIED: .planning/PROJECT.md:53-60] |
| Environment templates and secret exclusion | Repository / Build | API / Backend; Browser / Client | Templates document inputs, ignore rules prevent accidental tracking, and CI/build commands supply values. [VERIFIED: .planning/REQUIREMENTS.md:8-12] |
| Configuration validation tests | Repository / Build | API / Backend; Browser / Client | Tests should exercise missing/valid backend settings and valid/invalid mobile compile-time inputs before later features depend on them. [VERIFIED: .planning/config.json:8-12] |

## User Constraints

No `CONTEXT.md` exists for this phase; the locked scope comes from the roadmap, requirements, project constraints, and architecture documents listed below. [VERIFIED: gsd-tools `init.phase-op 1` output; .planning/ROADMAP.md:31-39]

## Exact Files to Create or Change

### Create

- `backend/requirements.txt` — pin the initial backend runtime dependencies; at minimum include FastAPI, Pydantic, and `pydantic-settings`. Exact FastAPI/httpx/Google/Supabase versions are Phase 2/3 decisions, not needed to solve CONF-01. [ASSUMED]
- `backend/app/__init__.py` and `backend/app/core/__init__.py` — make the planned package layout importable on all supported Python invocations. [ASSUMED]
- `backend/app/core/config.py` — `Settings(BaseSettings)` with required `GEMINI_API_KEY`, `SUPABASE_URL`, and `SUPABASE_SERVICE_ROLE_KEY`; configure `env_file=".env"` and expose a cached settings accessor. The variable names are present in the supplied backend reference. [VERIFIED: aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md:103-108]
- `backend/.env.example` — safe placeholders and comments; no live keys. [ASSUMED]
- `backend/tests/test_config.py` — isolated tests for valid env loading, missing required values, and `.env` behavior. [ASSUMED]
- `mobile/.env.example` — documentation-only template for the same public build inputs; Flutter will not read it automatically. [ASSUMED]
- `mobile/lib/core/config/app_env.dart` — const `AppEnv` that reads `String.fromEnvironment`, applies only documented non-secret defaults, and rejects empty/invalid required values. [ASSUMED]
- `mobile/test/core/config/app_env_test.dart` — unit tests for the validation logic using injectable constructor values or a test factory. [ASSUMED]

### Change

- `mobile/lib/core/network/api_client.dart:7-15` — replace `static const String baseUrl = 'https://aaharai-backend.onrender.com'` with `AppEnv` output. [VERIFIED: mobile/lib/core/network/api_client.dart:7-15]
- `mobile/lib/main.dart:1-20` — initialize/validate `AppEnv` before `runApp`, or ensure the provider that creates `ApiClient` reads the validated value. [VERIFIED: mobile/lib/main.dart:7-20]
- `mobile/.gitignore` — add `.env`, `.env.*`, and negate only `.env.example` if using the broad pattern. Preserve the existing Flutter ignores. [VERIFIED: mobile/.gitignore:1-47]
- `backend/.gitignore` — add `.env` and local secret variants; keep `.env.example` tracked. [ASSUMED]
- `mobile/test/widget_test.dart:1-14` — update only if the new startup validation requires test defines or a test-safe constructor. [VERIFIED: mobile/test/widget_test.dart:1-14]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pydantic-settings` [WARNING: legitimacy check returned SUS; verify before install] | 2.15.0 observed on PyPI | `BaseSettings`, dotenv loading, and typed environment validation | Pydantic v2 moved settings management into the separate package. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/] |
| `pydantic` [WARNING: legitimacy check returned SUS; verify before install] | 2.13.5 observed on PyPI | Typed validation base used by settings and later API contracts | The backend reference requires Pydantic v2 contracts. [VERIFIED: aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md:15-20] |
| Dart `String.fromEnvironment` | Flutter/Dart SDK | Compile-time mobile configuration | It reads the compilation configuration environment and supports `defaultValue`; presence can be checked with `bool.hasEnvironment`. [CITED: https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `pytest` [ASSUMED] | Resolve with the backend toolchain | Backend settings tests | Use for deterministic environment isolation; do not import application globals before monkeypatching the environment. |
| `flutter_test` | SDK-provided | `AppEnv` and widget tests | Already present in `mobile/pubspec.yaml:35-38`. [VERIFIED: mobile/pubspec.yaml:35-38] |

**Installation:**

```text
backend: python -m pip install -r requirements.txt
mobile: flutter pub get
```

The exact package pins must be checked at implementation time. PyPI reported `pydantic` 2.13.5 and `pydantic-settings` 2.15.0 on this machine, but the legitimacy seam marked both SUS (`too-new`, `unknown-downloads`), so the planner must add a human verification checkpoint before installing them. [VERIFIED: pip index versions; gsd-tools package-legitimacy check]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `pydantic` | PyPI | Published 2026-08-28 | Unknown to seam | github.com/pydantic/pydantic | SUS | Flagged — planner must add `checkpoint:human-verify` |
| `pydantic-settings` | PyPI | Published 2026-08-07 | Unknown to seam | github.com/pydantic/pydantic-settings | SUS | Flagged — planner must add `checkpoint:human-verify` |

**Packages removed due to SLOP verdict:** none.  
**Packages flagged as suspicious SUS:** `pydantic`, `pydantic-settings`. These are documented by the official Pydantic site, but the legitimacy gate did not return OK; do not call them `[VERIFIED]` packages. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/]

## Architecture Patterns

### Backend settings boundary

Use one `Settings` class in `backend/app/core/config.py`, with required fields and a settings factory. Keep settings construction out of endpoint modules so Phase 2 can inject one configuration boundary. Pydantic Settings documents `BaseSettings` and `SettingsConfigDict(env_file=...)`; its dotenv source is an input source, not a replacement for typed validation. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/]

The `.env` path is relative to the process working directory. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/] Therefore Render/local commands must run from `backend`, or the implementation should deliberately use an explicit path; do not silently depend on the IDE’s working directory. [ASSUMED]

### Mobile compile-time configuration

Read values with const declarations and validate the resulting strings once:

```dart
// Illustrative skeleton; names are proposed for Phase 1, not existing repository values.
class AppEnv {
  static const apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

`API_BASE_URL`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY` are proposed contract names. [ASSUMED] Validate URL scheme/host and require the two Supabase values unless the documented local default policy explicitly permits otherwise. `String.fromEnvironment` does not itself reject malformed or absent input; absence returns the supplied default (or empty string). [CITED: https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html]

Build examples should be documented in `README` or a phase-owned setup document:

```text
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=SUPABASE_URL=https://project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=public-anon-value
```

The Android emulator’s `10.0.2.2` choice is a local-development convention and must remain a documented default only, never a production endpoint. [ASSUMED]

### Anti-Patterns to Avoid

- **Importing `BaseSettings` from `pydantic`:** Pydantic v2 settings support is in `pydantic-settings`; use the separate package. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/]
- **Calling `os.getenv` throughout the backend:** the current reference does this in endpoint-era sample code and returns `None` when values are absent; replace it with one typed, failing settings boundary. [VERIFIED: aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md:103-108]
- **Using a runtime mobile dotenv loader:** this conflicts with the requested `--dart-define` contract and adds another source of truth. [VERIFIED: .planning/REQUIREMENTS.md:8-12]
- **Putting service-role or Gemini keys in Dart defines/templates:** mobile configuration is not a secret store; only public/anonymous Supabase settings belong there. [VERIFIED: .planning/PROJECT.md:53-60]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Typed backend env parsing | Manual `os.getenv` checks and ad-hoc casts | `pydantic-settings` `BaseSettings` | Centralizes required-field errors, type conversion, and dotenv source handling. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/] |
| Flutter compile-time lookup | A custom file parser or runtime dotenv mechanism | Dart `String.fromEnvironment` and `bool.hasEnvironment` | These are the SDK’s compile-time configuration primitives. [CITED: https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html] |
| Secret exclusion | Relying on developer discipline | Git ignore rules plus safe example files | The requirement explicitly needs ignored real env files and safe templates. [VERIFIED: .planning/REQUIREMENTS.md:8-12] |

## Common Pitfalls

1. **Pydantic v1/v2 import mismatch:** `BaseSettings` import paths differ; lock compatible `pydantic`/`pydantic-settings` versions and test the actual interpreter. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/]
2. **Wrong dotenv working directory:** a relative `.env` path can work from `backend` and fail from repository root. Add a test with an explicit temporary env file and document the launch directory. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/]
3. **Defaults masking missing production values:** only allow a documented local API URL default; required server secrets and production public settings must fail clearly. [ASSUMED]
4. **Gitignore pattern accidentally ignores templates:** use a negation rule such as `!.env.example`, then verify with `git check-ignore -v`. [CITED: https://git-scm.com/docs/gitignore]
5. **Dart validation deferred too long:** a missing define becomes an empty string/default; fail before the first request and show the key name, not its value. [CITED: https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html]
6. **Widget tests depending on developer defines:** keep `AppEnv` validation injectable or provide test construction so `flutter test` is deterministic. [ASSUMED]
7. **Inconsistent public naming:** choose one exact set of `--dart-define` keys and reuse it in templates, README, code, and CI. [ASSUMED]

## Code Examples

The repository’s current backend reference uses the exact secret names `GEMINI_API_KEY`, `SUPABASE_URL`, and `SUPABASE_SERVICE_ROLE_KEY`. [VERIFIED: aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md:103-108] The implementation should bind those names in one settings class:

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    GEMINI_API_KEY: str
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
```

This is a pattern example, not a claim that the file already exists. [ASSUMED] Required fields cause construction to fail when no value is supplied; assert the actual `ValidationError` in tests rather than testing only a truthy value. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 1 introduces no persistence layer; backend is absent. [VERIFIED: .planning/STATE.md:27-29] | None |
| Live service config | None verified — no backend or deployed-service config is present in the repository; external Render/Supabase dashboards were not inspected. [VERIFIED: .planning/codebase/STACK.md:63-67] | Add later deployment configuration in Phase 9; do not claim external state is empty. |
| OS-registered state | None relevant to this configuration foundation; no registrations were found in the repository audit. [ASSUMED] | None |
| Secrets/env vars | No tracked env files found; existing code hardcodes only the backend URL. [VERIFIED: mobile/lib/core/network/api_client.dart:7-15] | Add ignored local files and templates; later deployment secrets must be entered outside git. |
| Build artifacts / installed packages | Flutter generated artifacts exist under `mobile/.dart_tool`/`mobile/ios/Flutter`; no backend package installation exists. [VERIFIED: .planning/codebase/STACK.md:19-21; repository audit] | Do not commit generated artifacts; run `flutter pub get` after config changes. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Flutter | Mobile config/tests | ✓ | 3.47.1; Dart 3.13.1 | — |
| Python | Backend config/tests | ✓ | 3.14.6 | Use project-supported Python 3.11+; verify dependency compatibility before standardizing 3.14. [VERIFIED: .planning/PROJECT.md:59; local probe] |
| pip | Backend dependency installation | ✓ | 26.1.2 | — |
| Node.js | GSD tooling only | ✓ | 24.19.0 | — |
| npm | GSD tooling only | ✓ | 11.17.0 | — |

No database, Render service, or Supabase credentials are required to implement or unit-test this phase. [ASSUMED]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) for mobile; `pytest` [ASSUMED] for backend |
| Config file | None detected for backend; `mobile/pubspec.yaml` defines `flutter_test`. [VERIFIED: mobile/pubspec.yaml:35-38] |
| Quick run command | `cd backend; python -m pytest tests/test_config.py -q` and `cd mobile; flutter test test/core/config/app_env_test.dart` [ASSUMED] |
| Full suite command | `cd mobile; flutter test` plus backend `python -m pytest` [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONF-01 | Valid `.env` values load; missing required secret raises a clear validation error | unit | `python -m pytest backend/tests/test_config.py -q` [ASSUMED] | ❌ Wave 0 |
| CONF-02 | Real env files are ignored while `.env.example` remains trackable | integration/repository | `git check-ignore -v backend/.env mobile/.env` [ASSUMED] | ❌ Wave 0 |
| CONF-03 | Dart defines load, defaults are documented, malformed/empty required values fail | unit | `flutter test mobile/test/core/config/app_env_test.dart` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate

- Per task commit: the focused backend or Flutter command above. [ASSUMED]
- Per wave merge: backend tests and `cd mobile; flutter test`. [ASSUMED]
- Phase gate: all configuration tests green, `flutter analyze`, and repository ignore checks pass. [ASSUMED]

### Wave 0 Gaps

- [ ] Create backend test infrastructure and `backend/tests/test_config.py`. [ASSUMED]
- [ ] Create `mobile/test/core/config/app_env_test.dart`. [ASSUMED]
- [ ] Add backend dependency pins and install only after the SUS package checkpoint. [VERIFIED: gsd-tools package-legitimacy check]
- [ ] Add ignore/template verification to the phase test/verification steps. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No for Phase 1 | Authentication is Phase 2/6 scope. [VERIFIED: .planning/ROADMAP.md:41-50; 86-95] |
| V3 Session Management | No for Phase 1 | Session work is Phase 6 scope. [VERIFIED: .planning/ROADMAP.md:86-95] |
| V4 Access Control | No for Phase 1 | RLS/auth work is later scope. [VERIFIED: .planning/ROADMAP.md:52-61; 86-95] |
| V5 Input Validation | Yes | Pydantic Settings required-field/type validation and strict `AppEnv` URL/value validation. [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/; https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html] |
| V6 Cryptography | No | No cryptographic implementation belongs in this phase; never log or expose secret values. [ASSUMED] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Committed `.env` or service-role key | Information disclosure | Ignore real env files, track placeholders only, and review staged files with `git diff --cached`. [CITED: https://git-scm.com/docs/gitignore] |
| Mobile binary contains backend secret | Information disclosure | Keep Gemini/service-role settings backend-only; mobile uses only public/anonymous settings. [VERIFIED: .planning/PROJECT.md:53-60] |
| Empty/malformed endpoint accepted | Tampering/availability | Validate before creating Dio and test invalid values. [ASSUMED] |
| Secret value included in validation/log output | Information disclosure | Report variable names and remediation, never values. [ASSUMED] |

## Verification Commands

```text
git check-ignore -v backend/.env mobile/.env
git check-ignore -v backend/.env.example mobile/.env.example   # should not report ignored
git diff --check
cd backend; python -m pytest tests/test_config.py -q
cd mobile; flutter test test/core/config/app_env_test.dart
cd mobile; flutter test
cd mobile; flutter analyze
```

The `git check-ignore` expectations follow Git’s ignore matching behavior; verify both ignored real files and intentionally tracked examples. [CITED: https://git-scm.com/docs/gitignore]

## Sources

### Primary (HIGH confidence)

- `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — phase scope, constraints, success criteria, and requirement IDs. [VERIFIED: repository files read this session]
- `.planning/codebase/STACK.md`, `.planning/codebase/ARCHITECTURE.md` — current files, hardcoded URL, and absent backend. [VERIFIED: repository files read this session]
- `aahar_ai_docs/Doc_01_Product_Architecture_Rules.md`, `aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md`, `aahar_ai_docs/Doc_08_Flutter_State_Navigation.md` — intended architecture and settings names. [VERIFIED: repository files read this session]
- PyPI `pip index versions` and GSD package-legitimacy check — observed versions and SUS audit. [VERIFIED: local tools]

### Secondary (MEDIUM confidence)

- Pydantic Settings official documentation: https://docs.pydantic.dev/latest/concepts/pydantic_settings/ [CITED]
- Dart API official documentation: https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html [CITED]
- Git official ignore documentation: https://git-scm.com/docs/gitignore [CITED]
- Flutter flavors/build documentation: https://docs.flutter.dev/deployment/flavors [CITED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Proposed mobile keys are `API_BASE_URL`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY`. | Exact Files; Architecture | Later CI/build scripts and mobile code would need renaming. |
| A2 | `10.0.2.2:8000` is the preferred Android-emulator local default. | Architecture | Developers may need a different host/default policy. |
| A3 | Backend tests will use pytest and no backend test config is needed beyond standard discovery. | Validation Architecture | A Wave 0 test setup/config may be required. |
| A4 | Relative `.env` loading should be anchored by running commands from `backend`. | Architecture | Render or IDE working-directory behavior could require an explicit path. |
| A5 | No external service configuration was inspected. | Runtime State Inventory | Deployment secrets may require a separate setup task. |

## Open Questions

1. **Should public Supabase values be required in every mobile build?** The requirement says public settings are supplied and validated, but does not define a permitted offline/default mode. [VERIFIED: .planning/REQUIREMENTS.md:10-12] Recommendation: require them unless product owner explicitly approves a local placeholder mode. [ASSUMED]
2. **Which exact FastAPI/Python pins should Phase 1 establish?** The project requires Python 3.11+ and FastAPI 0.110+, but this phase has no backend package manifest. [VERIFIED: .planning/PROJECT.md:51,59] Recommendation: keep non-configuration service dependencies for Phase 2 and pin only the settings foundation here. [ASSUMED]
3. **Should backend settings expose uppercase attributes or normalized lowercase fields?** The reference uses uppercase environment names directly. [VERIFIED: aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md:103-108] Recommendation: use idiomatic lowercase Python attributes with explicit aliases only if Phase 2’s callers require it. [ASSUMED]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `BaseSettings` imported from `pydantic` v1 | Separate `pydantic-settings` package for Pydantic v2 | Pydantic v2-era API [CITED: https://docs.pydantic.dev/latest/concepts/pydantic_settings/] | Requirements must pin compatible package versions and test imports. |
| Mobile endpoint hardcoded in Dart | Compile-time `--dart-define` values | Phase 1 target [VERIFIED: .planning/PROJECT.md:62-70; mobile/lib/core/network/api_client.dart:7-15] | Build commands select environments without source edits. |

**Deprecated/outdated:** Treating `os.getenv` calls scattered through service code as configuration management; the supplied reference shows this pattern but Phase 1 should replace it with the typed boundary. [VERIFIED: aahar_ai_docs/Doc_03_Backend_FastAPI_Endpoints.md:103-108]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — official docs and registry checks are available, but the legitimacy seam flagged the observed package releases SUS. [VERIFIED: local tools]
- Architecture: HIGH — repository architecture and target file responsibilities were read directly. [VERIFIED: .planning/codebase/ARCHITECTURE.md:28-47; aahar_ai_docs/Doc_01_Product_Architecture_Rules.md:56-110]
- Pitfalls: MEDIUM — Pydantic/Dart behavior is officially documented; project-specific launch/CI conventions remain unimplemented. [CITED: official URLs above]

**Research date:** 2026-09-02  
**Valid until:** 2026-10-02 for stable configuration patterns; re-check package versions before installation.
