# Coding Conventions

**Analysis Date:** 2026-09-02

## Naming Patterns

**Files:**
- Lowercase snake_case, such as `api_client.dart` and `food_analysis_model.dart`.

**Functions:**
- Dart lowerCamelCase, such as `processBarcode` and `sanitizeResponse`.

**Variables:**
- Private fields use a leading underscore; constants use lowerCamelCase or `static const`, e.g. `_selectedDate` and `_targetCalories`.

**Types:**
- PascalCase for classes and enums; enum values are lowerCamelCase (`SafetyCategory.moderate`).

## Code Style

**Formatting:**
- Dart formatter style with trailing commas and two-space indentation is used throughout `mobile/lib/`.

**Linting:**
- `mobile/analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`; no project-specific rules are enabled.

## Import Organization

**Order:**
1. Dart/Flutter and package imports.
2. Relative imports for core, features, and shared code.

**Path Aliases:**
- No alias configuration detected; relative imports are used.

## Error Handling

**Patterns:**
- Async scanner methods catch errors and set Riverpod `AsyncValue.error` in `mobile/lib/features/scanner/controllers/scanner_controller.dart`.
- Model parsing uses null-safe defaults rather than throwing for absent API fields.
- Broad ignored catches are used for retry failure and server warm-up in `mobile/lib/core/network/api_client.dart`.

## Logging

**Framework:** None detected.

**Patterns:**
- Do not rely on console output; current production code has no structured logging.

## Comments

**When to Comment:**
- Comments explain policy intent, design-token origin, and retry behavior, e.g. `mobile/lib/core/theme/app_theme.dart` and `mobile/lib/core/network/api_client.dart`.

**JSDoc/TSDoc:**
- Dart doc comments are used for public compliance helpers in `mobile/lib/core/utils/safety_filter.dart`; most widgets are self-explanatory without documentation.

## Function Design

**Size:** Screens contain sizeable `build` methods and local helper builders; new code should extract repeated sections when behavior grows.

**Parameters:** Prefer named `required` constructor parameters and `super.key`, as shown by feature screens and shared widgets.

**Return Values:** Use typed futures and model objects at integration boundaries; current API methods return `Map<String, dynamic>` and should be narrowed when contracts stabilize.

## Module Design

**Exports:** Direct class imports; no barrel files detected.

**Barrel Files:** Not used. Preserve feature-local imports unless a deliberate public module boundary is introduced.

---

*Convention analysis: 2026-09-02*
