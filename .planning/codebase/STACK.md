# Technology Stack

**Analysis Date:** 2026-09-02

## Languages

**Primary:**
- Dart (SDK constraint `^3.3.0`) - Flutter application in `mobile/lib/`

**Secondary:**
- Kotlin/Gradle - Android host/build files under `mobile/android/`
- Markdown - product and architecture specifications under `aahar_ai_docs/`

## Runtime

**Environment:**
- Flutter mobile/web runtime; Android project is configured in `mobile/android/`

**Package Manager:**
- Flutter Pub
- Lockfile: `mobile/pubspec.lock` present

## Frameworks

**Core:**
- Flutter with Material 3 - cross-platform UI (`mobile/lib/main.dart`)
- Riverpod `^2.5.1` - dependency injection and scanner async state
- go_router `^14.0.1` - navigation and shell bottom navigation

**Testing:**
- `flutter_test` - one widget smoke test in `mobile/test/widget_test.dart`

**Build/Dev:**
- Flutter tooling
- `flutter_lints` `^3.0.0` - analyzer baseline in `mobile/analysis_options.yaml`
- Android Gradle Kotlin DSL - `mobile/android/*.gradle.kts`

## Key Dependencies

**Critical:**
- `dio` `^5.4.3+1` - HTTP client and multipart image upload in `mobile/lib/core/network/api_client.dart`
- `mobile_scanner` `^5.1.1` - barcode scanning UI
- `camera` `^0.10.5+9`, `image_picker` `^1.1.0` - label/image capture
- `image` `^4.1.7` - image processing dependency

**Infrastructure:**
- `path_provider` `^2.1.3` - local filesystem support
- `google_fonts` `^6.2.1`, `flutter_svg`, `intl` - presentation utilities

## Configuration

**Environment:**
- No runtime environment-file configuration is detected.
- Backend URL is hardcoded as `https://aaharai-backend.onrender.com` in `mobile/lib/core/network/api_client.dart`.

**Build:**
- `mobile/pubspec.yaml`, `mobile/analysis_options.yaml`, `mobile/android/app/src/main/AndroidManifest.xml`
- Launcher icon settings are declared in `mobile/pubspec.yaml`.

## Platform Requirements

**Development:**
- Flutter SDK compatible with Dart `^3.3.0`; Android/iOS tooling as required by Flutter plugins.

**Production:**
- Android application host exists; iOS, web, and other Flutter platform scaffolds are present.
- No backend source, deployment configuration, CI pipeline, or release signing configuration is present in the repository.

---

*Stack analysis: 2026-09-02*
