# Doc 01: Master Product & System Architecture Rules

## 1. System Identity & Mission Boundary
- **Product Name**: AaharAi
- **Entity**: asiverticals.me (Founder: Solo Student Founder)
- **Deployment Budget**: Strictly $0.00 (All architectural tiers must reside on zero-cost tiers)
- **Core Value Proposition**: Translate cryptic Indian packaged food labels, chemical additives (INS numbers), and unbranded street food into transparent, plain-language nutritional intelligence.
- **Compliance Boundary**: AaharAi is strictly an educational and food-transparency tool. It is **NOT** a medical diagnostic device, clinical engine, or therapeutic advisor. System outputs must never state or imply disease curing, treatment, prevention, or life-extension guarantees.

---

## 2. Global Architecture Diagram

                          +-------------------------+
                          |   Flutter Mobile App    |
                          | (Android First / iOS)   |
                          +-------------------------+
                             /          |          \
                (Auth Token)/           |           \(Direct Sync / Offline)
                           /            |            \
                          v             |             v
             +-------------------+      |      +-------------------+
             |   Firebase Auth   |      |      |     Supabase      |
             |  (Google Sign-In) |      |      |  (PostgreSQL DB   |
             +-------------------+      |      |    + Storage)     |
                                        |      +-------------------+
                                        v
                             +---------------------+
                             |   FastAPI Backend   |
                             |  (Render Free Tier) |
                             +---------------------+
                                    /       \
                    (Barcode Cache)/         \(Multimodal OCR / Parsing)
                                  v           v
                +--------------------+     +------------------------+
                |   Open Food Facts  |     | Google AI Studio       |
                |      REST API      |     | (Gemini 2.5 Flash)     |
                +--------------------+     +------------------------+

---

## 3. Technology Stack & Free-Tier Operational Constraints

| Layer | Service / Technology | Free-Tier Constraints & Safeguards |
| :--- | :--- | :--- |
| **Mobile Client** | Flutter (Dart >=3.3.0) | Cross-platform, single codebase. Local cache via Hive to reduce unnecessary API hits. |
| **Authentication** | Firebase Auth | Native Google Sign-In provider; zero cost, unlimited token verification. |
| **Relational Database** | Supabase (PostgreSQL 15+) | 500 MB quota cap. Strict Row Level Security (RLS) enforcement. Connection pooling via port `6543`. |
| **Application Backend** | FastAPI (Python 3.11+) hosted on Render | Spin-down occurs after 15 minutes of inactivity. App client must fire a light background `/health` ping upon camera launch to eliminate cold-start lag. |
| **Barcode Database** | Open Food Facts (OFF) API | Free public crowdsourced database. Strict rate-limit: 15 req/min. Enforce custom `User-Agent`. |
| **Multimodal Intelligence**| Gemini 2.5 Flash (Google AI Studio) | Free Tier limits (RPM/TPM/RPD). Enforce structured JSON schemas, strict base64 image downscaling (768x768 max), and exponential backoff retry algorithms. |
| **Monetization Engine** | Google AdMob + Play Billing | Non-intrusive banner ads inside History/Diary; interstitial ads strictly deferred until the user dismisses an analysis result card. |

---

## 4. Repository & Directory Structure (Clean Architecture)

Antigravity must adhere strictly to this split-folder or monorepo structure:

aahar_ai/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── deps.py                  # Database sessions & auth token validation
│   │   │   └── v1/
│   │   │       ├── endpoints/
│   │   │       │   ├── barcode.py       # OFF lookup -> Cache -> Gemini fallback
│   │   │       │   ├── vision.py        # Camera ingredient label OCR endpoint
│   │   │       │   ├── street_food.py   # Unpacked Indian food estimation engine
│   │   │       │   └── diary.py         # Calorie and macro logging routes
│   │   │       └── router.py            # APIRouter registration
│   │   ├── core/
│   │   │   ├── config.py                # Environment variables (BaseSettings)
│   │   │   ├── errors.py                # Global exception handlers (429, 502, 404)
│   │   │   └── security.py              # Firebase JWT decoding
│   │   ├── domain/
│   │   │   ├── fssai_rules.py           # INSAdditive tables, 8 Allergen categories
│   │   │   └── ifct_standards.py        # Indian Food Composition Tables baseline
│   │   ├── schemas/
│   │   │   ├── analysis.py              # Pydantic schemas for Gemini Structured Output
│   │   │   └── diary.py                 # Request/Response schemas for food logs
│   │   ├── services/
│   │   │   ├── gemini_service.py        # google-genai interactions client
│   │   │   ├── off_service.py           # httpx client for Open Food Facts
│   │   │   └── supabase_service.py      # Cache read/write operations
│   │   └── main.py                      # FastAPI root initialization & CORS
│   ├── Dockerfile
│   └── requirements.txt
│
└── mobile/
├── android/
├── ios/
├── assets/
│   ├── icons/
│   └── illustrations/
└── lib/
├── core/
│   ├── constants/               # API endpoints, colors, design tokens
│   ├── network/                 # Dio client with retry interceptor
│   ├── theme/                   # Material 3 light/dark wellness themes
│   └── utils/                   # Image compression & formatting helpers
├── features/
│   ├── auth/                    # Firebase Google Sign-In presentation & logic
│   ├── scanner/                 # MobileScanner & camera capture flow
│   ├── analysis/                # Ingredient breakdown UI & safety chips
│   ├── street_food/             # Unpacked dishes catalog & search
│   └── diary/                   # Calorie dashboard, radial macro charts
├── shared/
│   └── widgets/                 # AdBanner, DisclaimerBanner, CustomButtons
└── main.dart                    # App setup, GoRouter & Riverpod Scope


---

## 5. Core Scanning & Execution Workflows

### Flow 1: Packaged Food with Barcode
1. User scans barcode via `mobile_scanner` in Flutter.
2. Flutter queries local SQLite/Hive cache first. If found, display immediately.
3. If miss, hit Backend `GET /api/v1/scan/barcode/{barcode}`:
   - Backend checks Supabase `food_cache` table.
   - If miss, calls Open Food Facts API with custom header `AaharAi/1.0 (founder@asiverticals.me)`.
   - If OFF returns product (`status: 1`): Raw ingredients & nutriments are packaged into a structured prompt sent to Gemini 2.5 Flash.
   - Gemini translates INS codes, extracts allergens, assigns safety categories (`safe`, `moderate`, `avoid`), and provides an everyday plain-language breakdown.
   - Output writes to Supabase `food_cache` and streams back to the mobile client.
   - If OFF returns `status: 0` (Not Found): Backend responds with HTTP `404`, triggering the mobile app's automated camera prompt: *"Barcode not found. Take a picture of the back ingredient list."*

### Flow 2: Packaged Food without Barcode (Image Vision Flow)
1. User captures a picture of the back-of-package ingredient list.
2. Flutter compresses the image locally to a maximum boundary of 1024x1024 (JPEG quality 80) to preserve text readability while staying within base token limits.
3. Uploads image to Backend `POST /api/v1/scan/vision`.
4. Backend invokes Gemini 2.5 Flash multimodal endpoint using `response_schema` matching `FoodAnalysisResponse`.
5. Gemini performs simultaneous OCR, FSSAI additive identification, allergen detection, and plain-language summarization.
6. Clean JSON response displays in the UI and caches in Supabase under generated signature hashes.

### Flow 3: Unpacked / Indian Street Food Flow
1. User searches or selects a standard dish (e.g., Momos, Samosa, Veg Chowmein, Chole Bhature).
2. Backend matches base ingredient distributions anchored against the **Indian Food Composition Tables (IFCT 2017)** (e.g., Maida outer shell + Cabbage/Paneer filler + Refined frying oil absorption percentages).
3. Gemini processes the standard preparation steps, highlighting the hidden phases (reused oil degradation, high refined starch density, high sodium levels in seasoning) in accessible, non-alarmist language.

### Flow 4: Daily Calorie & Macro Logging
1. User reviews the scan result and taps **"Log to Diary"**.
2. User adjusts portion size (default: 100g or 1 serving).
3. App writes meal entry to Supabase `food_logs` table under the authenticated user UID via Row Level Security (RLS).
4. Diary updates: Daily calorie target bar fills and protein/carbs/fat rings calculate remaining intake.

---

## 6. Strict Non-Functional Requirements & Guardrails

### 1. Zero-Cost Free-Tier Optimization Rules
- **Database**: Never store raw user-uploaded camera images in Supabase Storage. Process images in memory or temporary buffers, parse the text via Gemini, and store only the resulting structured JSON string.
- **AI Token Management**: Never send large context history or chat histories. Keep all prompts single-turn, zero-shot, or few-shot using strict Pydantic JSON validation.
- **OFF Rate Limiting**: Implement a 2-second rate-limiting throttle per client IP to comply with Open Food Facts guidelines (maximum 15 req/min).

### 2. Code Quality & Antigravity Automation Instructions
- **No Hallucinated Types**: When writing Dart models, do not use untyped dynamic mappings (`Map<dynamic, dynamic>`). Use `freezed` or concrete `fromJson`/`toJson` data contracts that mirror backend Pydantic models exactly.
- **Fail-Safe Fallbacks**: Every network call must feature a local try-catch block with graceful user feedback. In cases of API rate limiting (`HTTP 429`), display: *"High network traffic. Retrying in a few seconds..."* with an exponential backoff.
- **State Management**: Use `flutter_riverpod` (v2.x) with code generation (`@riverpod`) to avoid boilerplate state leaks.

### 3. Regulatory & Store Policy Enforcements
- **Mandatory Non-Medical Disclaimer**: Every scan result screen must include a sticky or clearly visible footer:
  > *"AaharAi provides general food information and education based on public standards. It does not diagnose, treat, or prevent any medical condition. Always consult a qualified healthcare provider for personalized medical advice."*
- **Vocabulary Blacklist**: The app client, system prompts, and marketing stringsmust never generate or contain the terms: `cure`, `curative`, `treatment`, `prescribe`, `disease reversal`, or `increase lifespan`.