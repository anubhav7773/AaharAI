import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../analysis/models/food_analysis_model.dart';
import 'street_food_controller.dart';

class StreetFoodIndexScreen extends ConsumerStatefulWidget {
  const StreetFoodIndexScreen({super.key});

  @override
  ConsumerState<StreetFoodIndexScreen> createState() =>
      _StreetFoodIndexScreenState();
}

class _StreetFoodIndexScreenState extends ConsumerState<StreetFoodIndexScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _isAnalyzing = false;

  final List<String> _categories = [
    'All',
    'Tibetan/Momos',
    'Indo-Chinese',
    'Chaat & Fried',
    'South Indian',
    'Breads & Rolls',
  ];

  final List<Map<String, dynamic>> _sampleStreetFoods = [
    {
      'name': 'Veg Steamed Momos',
      'portion': '6 pcs (150g)',
      'category': 'Tibetan/Momos',
      'calories': 280,
      'protein': 6.2,
      'carbs': 48.0,
      'fat': 4.5,
      'cautions': ['Refined Maida Casing', 'High Sodium Red Chutney'],
      'isWarning': false,
      'prepInsight':
          'Steamed casing uses refined wheat flour (Maida). Accompanying spicy red chutney contains high garlic and chili with added sodium.',
    },
    {
      'name': 'Crispy Potato Samosa',
      'portion': '1 pc (120g)',
      'category': 'Chaat & Fried',
      'calories': 320,
      'protein': 4.5,
      'carbs': 38.0,
      'fat': 17.5,
      'cautions': ['Reused Oil Factor', 'High Saturated Lipids'],
      'isWarning': true,
      'prepInsight':
          'Deep fried at commercial street stalls often in repeatedly heated oil, increasing total polar compounds and trans fats.',
    },
    {
      'name': 'Pani Puri / Golgappe',
      'portion': '6 puris (180ml)',
      'category': 'Chaat & Fried',
      'calories': 210,
      'protein': 3.5,
      'carbs': 34.0,
      'fat': 7.0,
      'cautions': ['Water Potability Check', 'High Acidity'],
      'isWarning': true,
      'prepInsight':
          'Flavored spicy mint water requires hygienic potable water verification. Low lipid density compared to other chaat.',
    },
    {
      'name': 'Veg Hakka Chowmein',
      'portion': '1 plate (250g)',
      'category': 'Indo-Chinese',
      'calories': 460,
      'protein': 8.0,
      'carbs': 68.0,
      'fat': 18.0,
      'cautions': ['Monosodium Glutamate', 'High Wok Sodium'],
      'isWarning': false,
      'prepInsight':
          'High heat stir fry with dark soy sauce and flavor enhancers. Refined wheat noodles with stir-fried cabbage and carrots.',
    },
    {
      'name': 'Masala Dosa + Sambar',
      'portion': '1 pc (200g)',
      'category': 'South Indian',
      'calories': 360,
      'protein': 7.5,
      'carbs': 52.0,
      'fat': 12.0,
      'cautions': ['Moderate Starch Density'],
      'isWarning': false,
      'prepInsight':
          'Fermented rice and black gram batter offers prebiotic advantages. Spiced potato mash filling adds easily digestible carbohydrates.',
    },
    {
      'name': 'Paneer Kathi Roll',
      'portion': '1 roll (220g)',
      'category': 'Breads & Rolls',
      'calories': 490,
      'protein': 16.5,
      'carbs': 46.0,
      'fat': 24.0,
      'cautions': ['Layered Paratha Oil', 'Mayonnaise Spread'],
      'isWarning': false,
      'prepInsight':
          'Good dairy protein density from paneer cubes, balanced by paratha cooked in vegetable ghee.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _queryBackendDish(String dishName) async {
    final cleanName = dishName.trim();
    if (cleanName.isEmpty || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);
    try {
      final item = await ref
          .read(streetFoodControllerProvider.notifier)
          .fetchDishAnalysis(cleanName);
      if (item != null && mounted) {
        final analysis = FoodAnalysisResponse.fromJson(item.toJson());
        context.push('/analysis', extra: analysis);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AaharTheme.textHeadline,
            content: Text(
              'Could not analyze "$cleanName" right now. Please verify internet connection.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze dish: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _analyzeStreetFood(Map<String, dynamic> item) {
    final foodName = item['name'] as String;
    final analysis = FoodAnalysisResponse(
      foodName: foodName,
      brandName: 'Street Food • IFCT Baseline (${item['portion']})',
      source: 'street_food',
      nutrients: NutrientProfile(
        calories100g: (item['calories'] as num).toDouble(),
        protein100g: (item['protein'] as num).toDouble(),
        carbs100g: (item['carbs'] as num).toDouble(),
        fat100g: (item['fat'] as num).toDouble(),
      ),
      allergensDetected: item['category'] == 'Tibetan/Momos'
          ? ['Gluten (Wheat)']
          : item['category'] == 'Breads & Rolls'
              ? ['Gluten', 'Milk Solids']
              : [],
      ingredients: [
        IngredientItem(
          name: 'Refined Wheat Flour (Maida)',
          simpleExplanation: 'Standard dough base for roadside snacks.',
          category: SafetyCategory.moderate,
          healthNote: 'High glycemic impact.',
        ),
        IngredientItem(
          name: 'Culinary Frying Oil',
          simpleExplanation: 'Vegetable cooking oil used for sautéing and frying.',
          category: item['isWarning'] == true
              ? SafetyCategory.avoid
              : SafetyCategory.moderate,
          healthNote: item['isWarning'] == true
              ? 'Potential repeated thermal degradation in street woks.'
              : 'Standard culinary lipid.',
        ),
        IngredientItem(
          name: 'Spice & Herb Seasoning',
          simpleExplanation: 'Traditional spice blends (coriander, cumin, chilies).',
          category: SafetyCategory.safe,
          healthNote: 'Natural aroma and antioxidant compounds.',
        ),
      ],
      preparationInsights: item['prepInsight'] as String?,
    );

    context.push('/analysis', extra: analysis);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final selectedCategory = _categories[_selectedCategoryIndex];

    final filteredFoods = _sampleStreetFoods.where((item) {
      final matchesSearch = query.isEmpty ||
          (item['name'] as String).toLowerCase().contains(query);
      final matchesCat =
          selectedCategory == 'All' || item['category'] == selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: AaharTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Street Food Intelligence',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AaharTheme.textHeadline,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subhead & Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unpacked roadside foods deconstructed via ICMR-NIN IFCT standards.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AaharTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AaharTheme.borderGrey),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (val) => _queryBackendDish(val),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search Momos, Chowmein, Samosa, Golgappe...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AaharTheme.textLight,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AaharTheme.textMuted,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                if (_isAnalyzing)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      color: AaharTheme.primaryGreen,
                      backgroundColor: Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal Filter Chips Row
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AaharTheme.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AaharTheme.primaryGreen
                            : AaharTheme.borderGrey,
                      ),
                    ),
                    child: Text(
                      _categories[index],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? Colors.white : AaharTheme.textHeadline,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // 2-Column Responsive Grid View
          Expanded(
            child: filteredFoods.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fastfood_outlined,
                            size: 48,
                            color: AaharTheme.textLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.trim().isNotEmpty
                                ? 'No curated dish found for "${_searchController.text.trim()}"'
                                : 'No street dishes matched your filter',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AaharTheme.textMuted,
                            ),
                          ),
                          if (_searchController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AaharTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _isAnalyzing
                                  ? null
                                  : () => _queryBackendDish(
                                        _searchController.text,
                                      ),
                              icon: _isAnalyzing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome,
                                      size: 18,
                                    ),
                              label: Text(
                                _isAnalyzing
                                    ? 'Analyzing with AI...'
                                    : 'Analyze "${_searchController.text.trim()}" with AI',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final item = filteredFoods[index];
                      final cautions = item['cautions'] as List<dynamic>;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AaharTheme.borderGrey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _analyzeStreetFood(item),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Calorie Badge
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AaharTheme.calorieOrange
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '~${item['calories']} kcal',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AaharTheme.calorieOrange,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: AaharTheme.textMuted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Dish Title
                                  Text(
                                    item['name'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AaharTheme.textHeadline,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['portion'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AaharTheme.textMuted,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Caution Alert Tag
                                  if (cautions.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFFDE68A),
                                        ),
                                      ),
                                      child: Text(
                                        cautions.first.toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
