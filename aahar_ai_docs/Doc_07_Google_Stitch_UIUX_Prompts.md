# Doc 07: Google Stitch UI/UX Prompts, Design System & Screen Specifications

## 1. Design Philosophy & Aesthetic Foundation
AaharAi ka visual language **Transparency, Health, and Cognitive Simplicity** par based hai[cite: 1]. Indian users complex technical food labels se overwhelmed hote hain; UI ka primary goal unhe visual relief aur instant clarity dena hai bina unhe daraaye[cite: 1, 2].

- **Aesthetic**: Minimalist Wellness & High-Legibility Utility.
- **Visual Style**: Clean surfaces, soft diffused drop-shadows (elevation 1 to 2), rounded friendly geometry, modern typography with balanced negative space.
- **Design Grid**: Strict 8-point baseline grid (`8dp`, `16dp`, `24dp`, `32dp`).
- **Corner Radii**:
  - Small Elements (Badges, Chips): `8dp`
  - Cards & Containers: `16dp`
  - Bottom Sheets & Modals: `28dp` top corners
  - Primary CTA Buttons: `14dp` or fully pill-shaped (`100dp`)

---

## 2. Design System Tokens & Color Palette

Antigravity and Google Stitch must enforce this strict hex token palette across all generated themes and components:

+--------------------------+------------+-------------------------------------------------------+
| Token Key                | Hex Code   | Usage Context                                         |
+--------------------------+------------+-------------------------------------------------------+
| primary_seed             | #1B5E20    | Deep Forest Herbal Green (Brand identity, CTA buttons)|
| primary_surface          | #E8F5E9    | Soft Mint Tint (Active tabs, card accents)            |
| surface_background       | #F8FAF9    | Off-White Canvas (Clean, non-glare background)        |
| surface_card             | #FFFFFF    | Pure White (Elevated card containers, sheets)         |
| text_headline            | #111827    | Rich Dark Charcoal (Headers, product titles)          |
| text_body                | #374151    | Slate Gray (Paragraphs, ingredient explanations)      |
| text_muted               | #6B7280    | Subtle Gray (Timestamps, secondary units, captions)   |
| divider_border           | #E5E7EB    | Hairline border dividers                              |
|                          |            |                                                       |
| -- SAFETY SEMANTIC TOKENS (FSSAI Categorization) --                                           |
| safety_safe_badge        | #16A34A    | Emerald Green (Natural, GRAS ingredients, safe INS)   |
| safety_safe_bg           | #DCFCE7    | Soft Green Container fill                             |
| safety_moderate_badge    | #D97706    | Warm Amber (Preservatives, ADI capped, high sugar)    |
| safety_moderate_bg       | #FEF3C7    | Soft Amber Container fill                             |
| safety_avoid_badge       | #DC2626    | Crimson Red (Carcinogen suspects, banned additives)   |
| safety_avoid_bg          | #FEE2E2    | Soft Red Container fill                               |
|                          |            |                                                       |
| -- MACRO NUTRIENT TOKENS --                                                                  |
| macro_calories           | #EA580C    | Fiery Orange (Energy metric)                          |
| macro_protein            | #0284C7    | Sky Blue (Muscle & tissue building)                   |
| macro_carbs              | #F59E0B    | Golden Amber (Energy carbohydrates)                   |
| macro_fat                | #8B5CF6    | Muted Purple (Dietary lipids)                         |
+--------------------------+------------+-------------------------------------------------------+


---

## 3. Screen-by-Screen Google Stitch Production Prompts

Copy-paste these exact, prompt-engineered directives into **Google Stitch** to generate screen layouts and code widgets:

### 3.1 Screen 1: Splash & Identity Gateway
```text
PROMPT FOR GOOGLE STITCH:
Design a clean, modern splash and welcome screen for mobile app "AaharAi".
Canvas: 390x844 (Mobile portrait).
Theme: Minimalist health wellness.
Background: Gradient starting from pure white #FFFFFF to very subtle mint green #F2F9F4 at the bottom.
Center Content:
- A polished, geometric logo featuring a leafy stylized food bowl combined with an AI circuit pulse in deep forest green (#1B5E20).
- App title "AaharAi" in bold, elegant sans-serif typography (#111827, 32sp, letter spacing -0.5px).
- Subtitle: "Know What You Eat • Molecule by Molecule" (#6B7280, 15sp, regular).
Bottom Section:
- Primary Action: Full-width elevated Google Sign-In button (#FFFFFF container, 1px border #E5E7EB, rounded 14dp, elevation 1). Contains authentic Google "G" emblem, text "Continue with Google" (#111827, 16sp, medium).
- Educational Disclaimer: Clean muted caption (#9CA3AF, 12sp, center-aligned): "AaharAi is an educational food awareness tool. Not a medical device."
3.2 Screen 2: Universal Scanner Viewfinder (Dual Barcode + OCR)
Plaintext
PROMPT FOR GOOGLE STITCH:
Design a dual-purpose camera viewfinder screen for "AaharAi".
Canvas: 390x844 (Full-screen camera overlay).
Background: Semi-transparent black scrim (#000000 with 40% opacity) with a rounded transparent viewport in the center.
Top Bar (Floating):
- Left: Back arrow icon (#FFFFFF).
- Center: Segmented Toggle Pill (Two tabs: "Barcode Scan" [Active, white pill, dark text] and "Label OCR Photo" [Inactive, clear container, white text]).
- Right: Flashlight icon button (#FFFFFF circle).
Center Viewport:
- 280x280dp square with 24dp rounded corners, framed by 4 thick neon sage green (#22C55E) corner brackets.
- A glowing horizontal laser sweep animation line moving up and down inside the viewport.
- Sub-text below viewfinder: "Point at barcode or back-of-pack ingredients" (#FFFFFF, 14sp, semi-bold with drop-shadow).
Bottom Dock (Floating Card):
- Elevated white card (#FFFFFF, rounded 28dp, padding 16dp).
- Content: Two quick action icons:
  1. "Upload from Gallery" (Photo library icon, label below).
  2. "Search Street Food" (Street food noodle bowl icon, label below, navigates to unpackaged foods).
- Shutter Button: Large double-ring circular green capture button (#1B5E20) visible only when "Label OCR Photo" tab is active.
3.3 Screen 3: Food Analysis & Molecule Breakdown (The Hero Result Screen)
Plaintext
PROMPT FOR GOOGLE STITCH:
Design a detailed nutritional transparency and ingredient breakdown screen for "AaharAi".
Canvas: 390x844 (Scrollable view).
Background: Clean off-white (#F8FAF9).
Header Bar:
- Left: Back chevron.
- Center: Title "Food Breakdown".
- Right: Bookmark/Favorite icon and Share icon.

Card 1: Product Header & Source Badge:
- White surface card (#FFFFFF, rounded 18dp, elevation 1, margin horizontal 16dp).
- Product Name: e.g., "Nutella Hazelnut Spread" (20sp, bold, #111827).
- Brand/Subhead: "Ferrero • 350g" (#6B7280, 14sp).
- Tag: Small pill badge "Scanned via Open Food Facts" (#E8F5E9 background, #1B5E20 text, 12sp).

Card 2: Macro Quick-Glance (Horizontal 4-Column Grid):
- 4 rounded sub-cards for: Calories (539 kcal, #EA580C), Protein (6.3g, #0284C7), Carbs (56.3g, #F59E0B), Fats (30.9g, #8B5CF6).
- Each cell has bold value on top, label and unit below.

Card 3: FSSAI Allergen Banner (Conditional):
- Warning banner (#FEF3C7 container, 1px solid #FDE68A, rounded 14dp, padding 12dp).
- Icon: Amber warning shield.
- Text: "Allergen Warning: Contains Hazelnuts (Tree Nuts), Milk Solids, Soy Lecithin" (#92400E, 13sp, semi-bold).

Card 4: Ingredient Molecule Breakdown (The Core Feature):
- Section Title: "Deconstructed Ingredients (8)" (18sp, bold, #111827).
- Vertical Stack of expandable ingredient cards:
  * Top of card: Ingredient title (e.g. "Sugar (Sucrose)" or "INS 322 - Soya Lecithin") in 15sp semi-bold.
  * Right side badge: Safety Pill:
    - If safe: Emerald badge (#DCFCE7 bg, #16A34A text, "Safe").
    - If moderate: Amber badge (#FEF3C7 bg, #D97706 text, "Moderate").
    - If avoid: Red badge (#FEE2E2 bg, #DC2626 text, "Avoid").
  * Body: One-line plain consumer translation: "Natural emulsifier extracted from soybeans; keeps oil and cocoa from separating." (#374151, 13sp).
  * Footnote: Regulatory context: "FSSAI Permitted Emulsifier. No ADI limit." (#6B7280, 11sp, italic).

Card 5: Street Food Preparation Insights (If applicable):
- Card with soft amber border detailing oil reuse, starch content, and preparation factors.

Sticky Bottom Dock:
- Fixed at bottom of screen with frosted glass blur (Glassmorphism).
- Button: Full-width elevated green button "Log to Daily Diary" (#1B5E20 background, #FFFFFF text, rounded 16dp, height 52dp).
- Mandatory Regulatory Disclaimer below button: "AaharAi provides educational nutrition insights. It is not a medical device and does not treat or cure diseases." (#9CA3AF, 11sp, center).
3.4 Screen 4: Street Food Directory & Exploration
Plaintext
PROMPT FOR GOOGLE STITCH:
Design an Indian Street Food Nutritional Discovery screen for "AaharAi".
Canvas: 390x844.
Background: Pure white canvas (#FFFFFF).
Top Section:
- Header: "Street Food Intelligence" (24sp, bold, #111827).
- Subhead: "Unpacked roadside foods deconstructed via ICMR-NIN IFCT standards." (#6B7280, 14sp).
- Search Bar: Rounded 16dp container (#F3F4F6), magnifying glass icon, placeholder "Search Momos, Chowmein, Samosa, Golgappe..." (#9CA3AF).

Category Chips Row (Horizontal Scroll):
- "All", "Chaat & Fried", "Indo-Chinese", "Tibetan/Momos", "South Indian", "Breads & Rolls". Active chip has deep green fill (#1B5E20), inactive has light gray fill (#F3F4F6).

Main Content (2-Column Grid or List):
- Food Item Cards:
  * High-res illustration/photo placeholder of the street dish with rounded corners.
  * Dish Name: "Veg Steamed Momo (6 pcs)" (#111827, 16sp, bold).
  * Baseline Calories badge: "~280 kcal • 100g" (#EA580C, 12sp).
  * Key Caution Tag: Small red/amber pill "Refined Flour Casing" or "Reused Frying Oil".
  * Tap action triggers street food AI breakdown modal.
3.5 Screen 5: Daily Calorie & Macro Tracker (Diary Tab)
Plaintext
PROMPT FOR GOOGLE STITCH:
Design a daily food diary and calorie tracking screen for "AaharAi".
Canvas: 390x844.
Background: Off-white (#F8FAF9).
Header:
- Date Selector: "< Today, 2 Sep >" with a mini calendar icon (#111827, 18sp, semi-bold).

Card 1: Calorie Budget Progress Card:
- White elevated card (#FFFFFF, rounded 20dp, padding 20dp, elevation 1).
- Large circular radial gauge or linear progress bar showing:
  * "1,420 / 2,000 kcal consumed" (Big bold 26sp numerals).
  * Remaining: "580 kcal remaining" (#16A34A, 14sp, medium).
- Below gauge: 3 mini linear progress indicators for Macros:
  * Carbs: 180g / 250g (Orange bar #F59E0B)
  * Protein: 48g / 60g (Blue bar #0284C7)
  * Fat: 42g / 65g (Purple bar #8B5CF6)

Card 2: Meal Logs Timeline:
- Categorized sections with header and "+" button:
  * "Breakfast" (e.g., 2 Wheat Roti + Dal - 310 kcal)
  * "Lunch" (e.g., Rice, Paneer Curry, Salad - 560 kcal)
  * "Snacks" (e.g., Packaged Biscuits scanned - 210 kcal)
  * "Dinner" (Empty state: "No items logged yet")
- Each entry displays serving size, calories, and a delete swipe action.

Card 3: AdMob Banner Safe Container:
- Clean, bordered slot reserved at the bottom: 320x50dp labeled subtly "Sponsored". Placed non-intrusively below all personal health metrics.
4. Flutter Theme Tokens (mobile/lib/core/theme/app_theme.dart)
Antigravity must use this exact theme configuration to ensure Flutter renders the exact colors designed by Google Stitch[cite: 2]:

Dart
import 'package:flutter/material.dart';

class AaharTheme {
  // Brand Color Constants
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primarySurface = Color(0xFFE8F5E9);
  static const Color scaffoldBg = Color(0xFFF8FAF9);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // Semantic Safety Colors
  static const Color safeGreen = Color(0xFF16A34A);
  static const Color safeGreenBg = Color(0xFFDCFCE7);
  static const Color moderateAmber = Color(0xFFD97706);
  static const Color moderateAmberBg = Color(0xFFFEF3C7);
  static const Color avoidRed = Color(0xFFDC2626);
  static const Color avoidRedBg = Color(0xFFFEE2E2);

  // Macro Indicators
  static const Color calorieOrange = Color(0xFFEA580C);
  static const Color proteinBlue = Color(0xFF0284C7);
  static const Color carbsAmber = Color(0xFFF59E0B);
  static const Color fatPurple = Color(0xFF8B5CF6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: cardWhite,
        background: scaffoldBg,
      ),
      fontFamily: 'Inter',
      cardTheme: CardTheme(
        color: cardWhite,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF111827)),
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}