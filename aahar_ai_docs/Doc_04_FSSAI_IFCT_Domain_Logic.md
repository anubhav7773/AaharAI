ing Order Weight/Volume Rule
- **Rule**: Ingredients must be listed in strictly descending order of ingoing weight $(m/m)$ or volume $(v/v)$ at the time of manufacture.
- **Parser Evaluation**: The first 3 ingredients constitute the primary bulk of the product (often refined flour, palm oil, or sugar). Additives appearing at the tail end represent micro-additions $(< 5\%)$.
- **Compound Ingredients (5% Threshold Rule)**: If an ingredient consists of sub-ingredients, they must appear in parentheses in descending order. If a compound ingredient makes up less than $5\%$ of the finished product, sub-ingredients do not require individual declaration unless they serve a technological additive function.
- **Added Water**: Must be declared unless forming part of brine, syrup, or broth, or lost via evaporation during manufacturing.

### 2.2 Date Marking & Shelf Life Heuristics
- **Format Requirements**:
  - Shelf life $\le 3$ months: Legally mandatory format is `DD/MM/YY`.
  - Shelf life $> 3$ months: Formats can be `MM/YY` or `DD/MM/YY`.
  - Grouping: Date of manufacture and Expiry/Use-by must be displayed together.
- **Exemptions**: Fresh produce, alcoholic beverages ($\ge 10\%$ ABV), vinegar, sugar confectionery, and chewing gums are legally exempt from expiry dates.

### 2.3 The 8 Mandatory FSSAI Allergen Categories
FSSAI mandates an explicit declaration format: `Contains: [Allergen Name]` or `May Contain: [Allergen Name]`. The parser must flag any presence of the following 8 categories:

| # | FSSAI Allergen Category | Display Keyword on Pack | Parsing Trigger Tokens |
| :--- | :--- | :--- | :--- |
| **1** | Gluten Cereals | `Wheat` / `Barley` / `Oats` | Wheat, Maida, Atta, Semolina, Suji, Rye, Barley, Spelt, Malt |
| **2** | Crustaceans | `Crustacean` | Prawns, Crabs, Shrimp, Krill, Lobster |
| **3** | Milk & Dairy | `Milk`[cite: 2] | Milk solids, Whey, Casein, Lactose, Butter, Ghee, Cheese, Paneer[cite: 2] |
| **4** | Eggs | `Egg`[cite: 2] | Whole egg powder, Egg albumin, Egg yolk, Lysozyme[cite: 2] |
| **5** | Fish | `Fish`[cite: 2] | Fish oil, Gelatin (fish origin), Isinglass[cite: 2] |
| **6** | Peanuts & Tree Nuts | `Nut`[cite: 2] | Groundnut, Peanut butter, Almond, Walnut, Pistachio, Cashew, Hazelnut[cite: 2] |
| **7** | Soybeans | `Soy`[cite: 2] | Soya lecithin, Soy protein isolate, Hydrolyzed soy protein, Soya flour[cite: 2] |
| **8** | Sulphites ($\ge 10\text{ mg/kg}$) | `Sulphite`[cite: 2] | Sulphur dioxide, Sodium metabisulphite, Potassium metabisulphite[cite: 2] |

---

## 3. Reference Table: 35 High-Frequency Food Additives (INS)

This lookup table provides plain-language translations, functional categories, and regulatory health classifications based on FSSAI guidelines[cite: 2]:

| INS Code | Official Additive Name | Functional Class | Plain Language Meaning ("Aam Aadmi") | Category | Health / Regulatory Limit Note[cite: 2] |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **INS 102** | Tartrazine | Synthetic Colour | Khane ko bright peela (yellow) rang dene ke liye use hota hai.[cite: 2] | `moderate` | Acceptable Daily Intake (ADI) bounded; Lead $\le 10\text{ mg/kg}$, Arsenic $\le 3\text{ mg/kg}$ limits.[cite: 2] |
| **INS 110** | Sunset Yellow FCF | Synthetic Colour | Food ko attractive santari-peela (orange-yellow) rang deta hai.[cite: 2] | `moderate` | Strict maximum usage limit $(mg/kg)$ enforced by FSSAI.[cite: 2] |
| **INS 122** | Carmoisine (Azorubine) | Synthetic Colour | Khane ko gehra lal (red) rang pradan karta hai.[cite: 2] | `avoid` | Strictly prohibited in infant foods; strict heavy metal impurity limits.[cite: 2] |
| **INS 124** | Ponceau 4R | Synthetic Colour | Khane ko bright red rang deta hai.[cite: 2] | `moderate` | Heavy metal impurities bounded: Lead $\le 10\text{ mg/kg}$, Arsenic $\le 3\text{ mg/kg}$.[cite: 2] |
| **INS 133** | Brilliant Blue FCF | Synthetic Colour | Packaged food aur drinks ko neela (blue) rang deta hai.[cite: 2] | `moderate` | Carry-over restriction; prohibited in infant and baby foods.[cite: 2] |
| **INS 150a-d**| Caramel (Types I-IV) | Colouring Agent | Sugar ko heat karke dark brown/black rang aur flavor banata hai.[cite: 2] | `moderate` | Type III & IV have maximum limits for 4-methylimidazole impurity.[cite: 2] |
| **INS 160a(i)**| Beta-Carotene | Natural Colour | Gajar jaisa natural orange-yellow rang pradan karta hai.[cite: 2] | `safe` | Heavy metal safety specifications apply; generally safe nutrient precursor.[cite: 2] |
| **INS 160b**| Annatto | Natural Colour | Plant seeds se nikala gaya peela-santari rang hai.[cite: 2] | `safe` | Purity limits and heavy metal thresholds (Lead $\le 10\text{ mg/kg}$) set.[cite: 2] |
| **INS 171** | Titanium Dioxide | Colour / Opacifier | Khane ko safed (white) rang aur opaque look deta hai.[cite: 2] | `avoid` | Strict purity rules: Lead $\le 2\text{ mg/kg}$, Arsenic $\le 1\text{ mg/kg}$. Global concerns over accumulation.[cite: 2] |
| **INS 200** | Sorbic Acid | Preservative | Fungus aur yeast ko rok kar shelf-life badhata hai.[cite: 2] | `safe` | Lead $\le 2\text{ mg/kg}$; prohibited in infant formulations.[cite: 2] |
| **INS 211** | Sodium Benzoate | Preservative | Acidic foods/drinks ko microbes aur yeast se bachata hai.[cite: 2] | `moderate` | Category-wise maximum limits; excess consumption bounded by strict ADI.[cite: 2] |
| **INS 220** | Sulphur Dioxide | Preservative / Antioxidant | Dried fruits aur juices ko kaala hone se bachata hai.[cite: 2] | `avoid` | Pungent gas; allergen trigger for asthmatics. Baby food carry-over strictly banned.[cite: 2] |
| **INS 223** | Sodium Metabisulphite | Preservative / Antioxidant | Natural color maintain rakhta hai aur spoilage rokta hai.[cite: 2] | `moderate` | Mandatory label declaration required for sulphite-sensitive individuals.[cite: 2] |
| **INS 249** | Potassium Nitrite | Preservative / Fixative | Meat snacks mein bacteria rokta hai aur pinkish color maintain karta hai.[cite: 2] | `avoid` | Toxic impurities strictly capped: Lead $\le 2\text{ mg/kg}$.[cite: 2] |
| **INS 270** | Lactic Acid | Acidity Regulator | Mild khatta taste deta hai aur freshness preserve karta hai.[cite: 2] | `safe` | Regulated under heavy metal testing standards (Lead $\le 2\text{ mg/kg}$).[cite: 2] |
| **INS 281** | Sodium Propionate | Preservative | Breads aur bakery items ko phaphoondi (mold) se bachata hai.[cite: 2] | `safe` | Purity $\ge 99\%$; Lead capped at $\le 5\text{ mg/kg}$.[cite: 2] |
| **INS 282** | Calcium Propionate | Preservative | Bread aur bakery items ko lambe time tak fresh rakhta hai.[cite: 2] | `safe` | Fluoride $\le 10\text{ mg/kg}$ and Lead $\le 5\text{ mg/kg}$ safety limits.[cite: 2] |
| **INS 300** | Ascorbic Acid (Vitamin C) | Antioxidant | Oxidation rok kar natural color aur taste bachata hai.[cite: 2] | `safe` | Purity standards (minimum $99\%$) strictly controlled.[cite: 2] |
| **INS 304** | Ascorbyl Palmitate | Antioxidant | Tel aur fats ko badboodar (rancid) hone se bachata hai.[cite: 2] | `safe` | Purity limits: Lead $\le 2\text{ mg/kg}$, Arsenic $\le 3\text{ mg/kg}$.[cite: 2] |
| **INS 320** | BHA | Synthetic Antioxidant | Namkeens aur fried snacks ko kharab hone se bachata hai.[cite: 2] | `avoid` | Strict usage limits fixed; bounded by Acceptable Daily Intake.[cite: 2] |
| **INS 330** | Citric Acid | Acidity Regulator | Nimbu jaisa refreshing khatta swad aur acidity control deta hai.[cite: 2] | `safe` | Heavy metal safety rules: Lead $\le 0.5\text{ mg/kg}$.[cite: 2] |
| **INS 331(iii)**| Trisodium Citrate | Acidity Regulator | Sourness ko balance karta hai aur cheese ko smooth rakhta hai.[cite: 2] | `safe` | Good Manufacturing Practice (GMP) compliant.[cite: 2] |
| **INS 334** | Tartaric Acid | Acidity Regulator | Imli jaisa teekha khatta swad deta hai.[cite: 2] | `safe` | Toxic maleic acid impurity capped at maximum $0.1\%$.[cite: 2] |
| **INS 338** | Phosphoric Acid | Acidity Regulator | Cola drinks ko sharp tangy taste deta hai.[cite: 2] | `moderate` | Excessive phosphorus intake impacts calcium absorption. Regulated by maximum limits.[cite: 2] |
| **INS 401** | Sodium Alginate | Thickener / Gelling | Liquids ko thick aur gel-like banata hai.[cite: 2] | `safe` | Viscosity standards and purity checks legally mandatory.[cite: 2] |
| **INS 407** | Carrageenan | Stabilizer / Thickener | Flavoured milk mein separation rok kar milk solids evenly rakhta hai.[cite: 2] | `moderate` | Microbial safety (negative for *E. coli* and *Salmonella*) mandatory.[cite: 2] |
| **INS 412** | Guar Gum | Thickener / Stabilizer | Sauces aur noodles ko thick aur stable banata hai.[cite: 2] | `safe` | Natural seed gum; Lead capped at $\le 2\text{ mg/kg}$.[cite: 2] |
| **INS 414** | Gum Arabic (Acacia) | Emulsifier / Stabilizer | Flavours aur oils ko liquid mein alag hone se rokta hai.[cite: 2] | `safe` | Natural plant exudate; must be free from pathogens.[cite: 2] |
| **INS 440** | Pectin | Gelling Agent | Jams aur jellies ko jamne (gel banne) mein madad karta hai.[cite: 2] | `safe` | Methanol $\le 1\%$, Lead $\le 2\text{ mg/kg}$ thresholds.[cite: 2] |
| **INS 466** | Sodium CMC | Stabilizer / Thickener | Ice creams aur sauces ko smooth banata hai aur crystallization rokta hai.[cite: 2] | `safe` | Purity $\ge 99.5\%$; controlled under heavy metals rules.[cite: 2] |
| **INS 476** | PGPR | Emulsifier | Chocolate ko smoothly flow hone deta hai taaki kam cocoa butter lage.[cite: 2] | `safe` | Copper/Zinc $\le 50\text{ mg/kg}$, Lead $\le 2\text{ mg/kg}$.[cite: 2] |
| **INS 503(ii)**| Ammonium Bicarbonate | Leavening Agent | Biscuits ko phula kar crispy aur light banata hai.[cite: 2] | `safe` | Arsenic $\le 0.6\text{ mg/kg}$, Lead $\le 2\text{ mg/kg}$ limits.[cite: 2] |
| **INS 621** | MSG (Monosodium Glutamate) | Flavour Enhancer | Food mein savoury umami taste badhata hai.[cite: 2] | `moderate` | GMP regulated. Cannot be added to foods for infants below 12 months.[cite: 2] |
| **INS 950** | Acesulfame Potassium | Artificial Sweetener | Cheeni se 200 guna zyada mithaas bina kisi calorie ke deta hai.[cite: 2] | `moderate` | ADI limits strictly enforced; must state artificial sweetener warnings.[cite: 2] |
| **INS 951** | Aspartame | Artificial Sweetener | Diet sodas aur desserts mein zero-calorie sweetness deta hai.[cite: 2] | `avoid` | Mandatory label warning for Phenylketonurics (contains phenylalanine).[cite: 2] |
| **INS 955** | Sucralose | Artificial Sweetener | Heat-stable artificial sweetener bina calories ke mithaas deta hai.[cite: 2] | `moderate` | Category-wise Maximum Use Levels enforced by FSSAI.[cite: 2] |
| **INS 960** | Steviol Glycosides | Natural Sweetener | Stevia plant leaves se nikali gayi non-caloric natural mithaas.[cite: 2] | `safe` | Purity $\ge 95\%$; JECFA monograph compliance required.[cite: 2] |

---

## 4. IFCT 2017 Baseline Nutritional Data (per 100g Edible Portion)

Antigravity uses this standardized ICMR-NIN reference table to calculate base component contributions[cite: 2]:

+--------------------------+-----------------------+---------+---------+---------+--------+
| Commodity / Base Item    | Primary Dish Usage    | Energy  | Protein | Carbs   | Fat    | Fiber  |
|                          |                       | (kcal)  | (g)     | (g)     | (g)    | (g)    |
+--------------------------+-----------------------+---------+---------+---------+--------+
| Wheat flour, atta        | Roti, Paratha, Puri   | 320.0   | 10.57   | 64.17   | 1.53   | 11.36  |[cite: 2]
| Wheat flour, maida       | Chowmein, Momo, Bun   | 352.0   | 10.36   | 74.27   | 0.76   | 2.76   |[cite: 2]
| Wheat semolina (Suji)    | Upma, Halwa, Golgappe | 334.0   | 11.38   | 68.43   | 0.74   | 9.72   |[cite: 2]
| Vermicelli (Noodle base) | Chowmein, Sewai       | 333.0   | 9.70    | 70.39   | 0.45   | 9.28   |[cite: 2]
| Rice, raw, milled        | Steamed Rice, Pulao   | 356.0   | 7.94    | 78.24   | 0.52   | 2.81   |[cite: 2]
| Rice flakes (Poha)       | Poha                  | 354.0   | 7.44    | 76.75   | 1.14   | 3.46   |[cite: 2]
| Rice puffed (Murmura)    | Bhel, Jhalmuri        | 362.0   | 7.47    | 77.68   | 1.62   | 2.56   |[cite: 2]
| Paneer                   | Momos, Tikka, Curries | 305.0   | 18.86   | 2.41    | 24.78  | 0.00   |[cite: 2]
| Milk, whole (Cow)        | Chai, Coffee, Kheer   | 73.0    | 3.26    | 4.94    | 4.48   | 0.00   |[cite: 2]
| Milk, whole (Buffalo)    | Curd, Sweets base     | 107.0   | 3.68    | 8.39    | 6.58   | 0.00   |[cite: 2]
| Toor / Arhar Dal         | Dal Tadka, Sambhar    | 331.0   | 21.70   | 55.23   | 1.56   | 9.06   |[cite: 2]
| Chana Dal (Bengal gram)  | Samosa, Besan batters | 329.0   | 21.55   | 46.72   | 5.31   | 15.15  |[cite: 2]
| Moong Dal (Green gram)   | Khichdi, Sprouted Dal | 294.0   | 22.53   | 46.13   | 1.14   | 17.04  |[cite: 2]
| Urad Dal (Black gram)    | Idli, Dosa, Makhani   | 324.0   | 23.06   | 51.00   | 1.69   | 11.93  |[cite: 2]
| Masoor Dal (Lentil)      | Red Lentil Curry      | 322.0   | 24.35   | 52.53   | 0.75   | 10.43  |[cite: 2]
| Cabbage, green           | Chowmein, Momo filler | 22.0    | 1.36    | 3.25    | 0.12   | 2.76   |[cite: 2]
| Onion, big               | Curries, Street food  | 48.0    | 1.50    | 9.56    | 0.24   | 2.45   |[cite: 2]
| Tomato, ripe             | Gravy, Ketchup base   | 20.0    | 0.90    | 2.71    | 0.47   | 1.77   |[cite: 2]
| Capsicum (Shimla Mirch)  | Chowmein, Manchurian  | 20.0    | 1.47    | 2.14    | 0.47   | 2.19   |[cite: 2]
| Edible Refined / Ghee    | Deep frying, Cooking  | 900.0   | 0.00    | 0.00    | 100.00 | 0.00   |[cite: 2]
+--------------------------+-----------------------+---------+---------+---------+--------+


---

## 5. Composite Dish Estimation Formulas (AI Baseline Calibration)

Street dishes do not appear as single line items in raw IFCT tables[cite: 2]. Antigravity applies these standardized component formulations to benchmark Gemini street food estimations[cite: 2]:

### 5.1 Veg Chowmein (per 100g Cooked)[cite: 2]
- **Formulation**: $60\text{g}$ Boiled Noodle base (Maida/Vermicelli) $+$ $30\text{g}$ Veggies (Cabbage, Capsicum, Onion) $+$ $10\text{g}$ Cooking Oil/Sauce mix[cite: 2].
- **Nutrient Calculation**:
  - Calories: $(0.60 \times 160) + (0.30 \times 30) + (0.10 \times 900) \approx 195\text{ kcal}$
  - Carbs: $\approx 28.5\text{g}$ | Protein: $\approx 3.8\text{g}$ | Fat: $\approx 10.5\text{g}$
- **Preparation Insights**: High thermal stir-frying with reused oil, sodium surge via soy sauce/MSG, and low fiber content due to refined wheat noodles[cite: 2].

### 5.2 Veg Steamed Momo (per 100g Cooked)[cite: 2]
- **Formulation**: $40\text{g}$ Outer Cover (Refined Maida dough) $+$ $60\text{g}$ Filling (Cabbage, Onion, minimal fat)[cite: 2].
- **Nutrient Calculation**:
  - Calories: $(0.40 \times 280) + (0.60 \times 35) \approx 133\text{ kcal}$
  - Carbs: $\approx 24.5\text{g}$ | Protein: $\approx 3.5\text{g}$ | Fat: $\approx 1.8\text{g}$
- **Preparation Insights**: Steaming avoids trans fats, but the casing consists of unfortified refined flour[cite: 2]. Accompanied spicy red chutney often introduces a high sodium spike[cite: 2].

### 5.3 Indian Samosa (per 100g Fried)[cite: 2]
- **Formulation**: $40\text{g}$ Outer Crust (Maida $+$ shortening) $+$ $45\text{g}$ Spiced Potato/Peas core $+$ $15\text{g}$ Deep-fry Absorbed Oil[cite: 2].
- **Nutrient Calculation**:
  - Calories: $(0.40 \times 352) + (0.45 \times 90) + (0.15 \times 900) \approx 316\text{ kcal}$
  - Carbs: $\approx 32.0\text{g}$ | Protein: $\approx 4.2\text{g}$ | Fat: $\approx 18.5\text{g}$
- **Preparation Insights**: Deep fried at commercial roadside stalls using repeatedly boiled cooking fat, triggering elevated Total Polar Compounds (TPC) and lipid degradation products[cite: 2].