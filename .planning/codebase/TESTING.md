# Testing Patterns

**Analysis Date:** 2026-09-02

## Test Framework

**Runner:**
- `flutter_test`
- Config: `mobile/pubspec.yaml`; no separate test-runner config detected.

**Assertion Library:**
- Flutter test matchers.

**Run Commands:**
```bash
cd mobile
flutter test          # Run detected tests
flutter analyze       # Static analysis
flutter test --coverage
```

## Test File Organization

**Location:**
- Separate `mobile/test/` directory.

**Naming:**
- `*_test.dart`; only `mobile/test/widget_test.dart` is present.

**Structure:**
```text
mobile/test/widget_test.dart
```

## Test Structure

**Suite Organization:**
```dart
testWidgets('AaharAiApp builds smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: AaharAiApp()),
  );
  expect(find.text('AaharAi'), findsWidgets);
});
```

**Patterns:**
- One direct widget smoke test.
- `ProviderScope` is supplied explicitly when bootstrapping the app.
- No setup/teardown, fixtures, golden tests, or test doubles are detected.

## Mocking

**Framework:** None detected.

**Patterns:** No mocking examples exist.

**What to Mock:**
- Future controller tests should inject a fake `ApiClient` or repository rather than making calls to the hardcoded Render URL.

**What NOT to Mock:**
- Keep pure model parsing and `HealthClaimFilter` tests real; they have no external dependency.

## Fixtures and Factories

**Test Data:** No shared fixtures or factories detected.

**Location:** Not applicable.

## Coverage

**Requirements:** None enforced.

**View Coverage:**
```bash
cd mobile
flutter test --coverage
```

## Test Types

**Unit Tests:**
- Not detected for `FoodAnalysisResponse`, scanner state, image utilities, or safety filtering.

**Integration Tests:**
- Not detected for Dio/API contracts, camera, barcode, or remote backend.

**E2E Tests:**
- Not detected.

## Common Patterns

**Async Testing:**
```dart
await tester.pumpWidget(const ProviderScope(child: AaharAiApp()));
```

**Error Testing:**
- No error assertions are currently present; add tests around `AsyncValue.error` and malformed payload defaults before expanding scan flows.

---

*Testing analysis: 2026-09-02*
