# Doc 10: Google Play Policy Compliance, Health Disclaimers & Safety Guardrails

## 1. Google Play Regulatory Classification & Developer Eligibility
AaharAi processes food labels, analyzes ingredients, and tracks daily calorie and macronutrient logs[cite: 1]. Under Google Play policies, this places the app within the scope of the **Health Content and Services Policy**.

### 1.1 Developer Account Eligibility
- **Individual Developer Accounts**: Google Play explicitly permits individual developers to publish health, wellness, and nutrition tracking applications.
- **Exemption from Medical Device Clearance**: Because AaharAi is strictly a dietary transparency and nutritional educational utility (and does not perform diagnostic triage, clinical biometric scanning, or medical device hardware control), government-affiliated medical certifications or medical device licenses are **NOT** required.

### 1.2 Mandatory Console Declaration Form
Prior to production rollout, complete the **Health Apps Declaration Form** in Google Play Console:
- **Location**: `Play Console > Monitor & Improve > Policy > App content > Health apps`.
- **Category Selection**: Choose `Diet, Nutrition & Fitness` / `General Health & Wellness`.
- **Medical Device Checkbox**: Select **"No"** (Confirming the app is not a certified medical device).

---

## 2. Mandatory Disclaimers (UI & Store Listing)

Google Play mandates two distinct, prominent disclaimers across the app interface and the public store listing:

### 2.1 Non-Medical Device Disclaimer
> *"AaharAi is not a medical device and does not diagnose, treat, cure, or prevent any medical condition."*

### 2.2 Healthcare Professional Consultation Reminder
> *"The information provided is for general educational and informational purposes only. Always consult a qualified physician or healthcare professional before making significant dietary changes or for medical advice."*

### 2.3 Required Placement Matrix
| Surface / Screen | Placement Location | Visual Style |
| :--- | :--- | :--- |
| **Play Store Description** | First paragraph of the Long Description and at the very bottom. | Plain uppercase or prominent text block. |
| **App Onboarding / Splash** | Beneath the primary Google Sign-In button[cite: 1]. | Centered caption, minimum font size `11sp`, `#9CA3AF`. |
| **Scan Result Screen** | Sticky footer dock below the "Log to Diary" button. | Readable caption, permanent fixture (not dismissible). |
| **Settings / About Screen** | Dedicated "Legal & Health Disclaimer" modal sheet. | Expandable complete legal text with active external privacy link[cite: 2]. |

---

## 3. Blacklisted Terminology & Prohibited Health Claims

Google Play strictly prohibits misleading or exaggerated health claims[cite: 2]. The marketing copy, system prompts, UI text, and AI responses must never use terms that claim therapeutic intervention or clinical results.

### 3.1 Prohibited Keywords vs. Permitted Educational Phrasing
| Prohibited Term / Phrase[cite: 2] | Violation Reason[cite: 2] | Permitted Compliant Alternative |
| :--- | :--- | :--- |
| `"Cure"` / `"Cures diabetes/obesity"`[cite: 2] | Unsubstantiated medical cure claim[cite: 2]. | *"Helps identify sugar and carb density."* |
| `"Treat"` / `"Treatment of ailments"`[cite: 2] | Medical intervention terminology[cite: 2]. | *"Supports informed nutritional awareness."* |
| `"Prevent disease"` / `"Cancer prevention"`[cite: 2] | Therapeutic prophylactic claim[cite: 2]. | *"Helps avoid high-concern synthetic additives."*[cite: 2] |
| `"Increase lifespan"` / `"Live longer"` | Unverifiable longevity guarantee[cite: 1, 2]. | *"Encourages balanced, conscious eating habits."* |
| `"Detoxify your body"` | Pseudo-scientific wellness claim. | *"Identifies heavily processed ingredients."* |
| `"Medically proven to..."` | Implies clinical drug equivalence[cite: 2]. | *"Based on FSSAI and ICMR-NIN public food data."*[cite: 2] |

---

## 4. Automated Content Filter Guardrail (`lib/core/utils/safety_filter.dart`)

Antigravity must integrate a client-side interceptor that scans incoming AI strings to ensure zero policy-violating keywords ever reach the UI:

```dart
class HealthClaimFilter {
  static final RegExp _prohibitedRegex = RegExp(
    r'\b(cure|cures|curing|treat|treatment|treating|prevent disease|prevents disease|reverses disease|increase lifespan|prolong life|clinical therapy)\b',
    caseSensitive: false,
  );

  /// Inspects any raw text from Gemini and replaces non-compliant words with neutral phrasing
  static String sanitizeResponse(String rawText) {
    return rawText.replaceAllMapped(_prohibitedRegex, (match) {
      final matchedWord = match.group(0)?.toLowerCase();
      switch (matchedWord) {
        case 'cure':
        case 'cures':
          return 'manage dietary intake';
        case 'treat':
        case 'treatment':
          return 'nutritional awareness';
        case 'prevent disease':
          return 'support dietary balance';
        case 'increase lifespan':
          return 'support overall well-being';
        default:
          return 'informed food choices';
      }
    });
  }
}
5. Public Privacy Policy Requirements (Health & AI Processing Data)
Google Play requires a dedicated, publicly accessible URL covering health and dietary logs[cite: 2]:

5.1 Hosting & Accessibility Rules
Format: Must be an active, publicly accessible web page (e.g., hosted on GitHub Pages, Supabase Storage, or asiverticals.me/privacy)[cite: 1, 2].

No PDF Allowed: Google Play policies explicitly prohibit linking to PDF documents for privacy policies[cite: 2].

5.2 Mandatory Disclosures Schema
Health Data Collection Scope: Disclose that the app collects and stores daily calorie goals, logged food items, portion quantities, and macronutrient breakdowns solely for personal tracking inside the user's account[cite: 2].

Third-Party AI Processing (Gemini API): State transparently:

"Images of food packaging and ingredient text submitted by the user are transmitted to the Google Gemini API solely for real-time text recognition, ingredient deconstruction, and nutritional parsing. Data processed on free-tier APIs may be logged by Google in accordance with Google AI Studio terms."

[cite: 2]

Open Food Facts API Data Source: Disclose that barcode queries are looked up against the crowdsourced, open-source database at Open Food Facts[cite: 1, 2].

Data Retention & Deletion: Users must be provided an option inside Settings > Account to delete their account and purge all records from the Supabase profiles and food_logs tables.

6. Pre-Submission Verification Checklist
Before submitting the app bundle (.aab) to Google Play Console, verify each item:

[ ] Health Apps Declaration: Completed in Play Console under Policy > App Content[cite: 2].

[ ] Store Listing Copy: Scanned and verified to contain zero instances of prohibited keywords (cure, treat, prevent, lifespan)[cite: 1, 2].

[ ] UI Disclaimer Banner: Verified visible on the onboarding flow and at the bottom of the scan result screen[cite: 2].

[ ] Privacy Policy Web Page: Live at a public URL (non-PDF) containing explicit health data and third-party AI disclosures[cite: 2].

[ ] Unused Permissions Stripped: AndroidManifest.xml contains only android.permission.CAMERA and android.permission.INTERNET. No location or contact permissions are included[cite: 2].