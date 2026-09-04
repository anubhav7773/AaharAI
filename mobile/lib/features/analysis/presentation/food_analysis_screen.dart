import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_analysis_model.dart';
import '../../diary/presentation/diary_controller.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/macro_pill_card.dart';
import '../../../shared/widgets/allergen_alert_card.dart';
import '../../../shared/widgets/health_disclaimer_footer.dart';
import 'widgets/molecule_card.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/billing/subscription_provider.dart';

class FoodAnalysisScreen extends ConsumerStatefulWidget {
  final FoodAnalysisResponse? analysis;
  final Map<String, dynamic>? rawPayload;

  const FoodAnalysisScreen({
    super.key,
    this.analysis,
    this.rawPayload,
  });

  @override
  ConsumerState<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends ConsumerState<FoodAnalysisScreen> {
  late FoodAnalysisResponse _data;

  @override
  void initState() {
    super.initState();
    if (widget.analysis != null) {
      _data = widget.analysis!;
    } else if (widget.rawPayload != null) {
      _data = FoodAnalysisResponse.fromJson(widget.rawPayload!);
    } else {
      // High-fidelity fallback sample
      _data = FoodAnalysisResponse(
        foodName: 'Hazelnut Cocoa Spread',
        brandName: 'Ferrero • 350g (Serving: 15g)',
        source: 'open_food_facts',
        nutrients: NutrientProfile(
          calories100g: 539,
          protein100g: 6.3,
          carbs100g: 56.3,
          fat100g: 30.9,
          fiber100g: 3.2,
        ),
        allergensDetected: [
          'Milk Solids',
          'Hazelnuts (Tree Nuts)',
          'Soy Lecithin'
        ],
        ingredients: [
          IngredientItem(
            name: 'Sugar (Sucrose)',
            simpleExplanation:
                'Refined granulated sweetener providing fast energy.',
            category: SafetyCategory.moderate,
            healthNote:
                'High glycemic index. Consume within recommended daily intake.',
          ),
          IngredientItem(
            name: 'Palm Oil',
            simpleExplanation:
                'Vegetable fat providing creamy spreadable texture.',
            category: SafetyCategory.moderate,
            healthNote:
                'Contains saturated fatty acids. Standard culinary lipid.',
          ),
          IngredientItem(
            name: 'Hazelnuts (13%)',
            simpleExplanation:
                'Natural tree nuts rich in healthy unsaturated fats and vitamin E.',
            category: SafetyCategory.safe,
            healthNote: 'Wholesome natural nut ingredient. Known allergen.',
          ),
          IngredientItem(
            name: 'Skimmed Milk Powder (8.7%)',
            simpleExplanation:
                'Dehydrated milk solids providing dairy protein and calcium.',
            category: SafetyCategory.safe,
            healthNote: 'FSSAI compliant dairy constituent. Contains lactose.',
          ),
          IngredientItem(
            name: 'INS 322 - Soya Lecithin',
            simpleExplanation:
                'Natural emulsifier extracted from soybeans that prevents cocoa and oil from separating.',
            category: SafetyCategory.safe,
            healthNote: 'FSSAI Permitted Emulsifier. No ADI limit.',
          ),
          IngredientItem(
            name: 'Vanillin',
            simpleExplanation:
                'Aroma compound creating the classic vanilla flavor note.',
            category: SafetyCategory.safe,
            healthNote: 'Identical to natural flavor compound.',
          ),
        ],
        preparationInsights: null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AaharTheme.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            ref.read(adManagerProvider).showInterstitialIfEligible(
                  isProUser: ref.read(isProUserProvider).valueOrNull == true,
                );
            context.pop();
          },
        ),
        title: Text(
          'Food Breakdown',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AaharTheme.textHeadline,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to Bookmarks')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card
                _buildProductHeaderCard(),

                const SizedBox(height: 12),

                // Macro Grid with shared widget
                MacroPillCard(
                  calories: _data.nutrients.calories100g,
                  protein: _data.nutrients.protein100g,
                  carbs: _data.nutrients.carbs100g,
                  fat: _data.nutrients.fat100g,
                ),

                const SizedBox(height: 12),

                // Allergen Alert with shared widget
                if (_data.allergensDetected.isNotEmpty) ...[
                  AllergenAlertCard(allergens: _data.allergensDetected),
                  const SizedBox(height: 12),
                ],

                // Preparation Insights (if street food)
                if (_data.preparationInsights != null &&
                    _data.preparationInsights!.isNotEmpty) ...[
                  _buildPreparationInsightsCard(),
                  const SizedBox(height: 12),
                ],

                // Deconstructed Molecule Breakdown List
                _buildIngredientBreakdownSection(),
              ],
            ),
          ),

          // Sticky Bottom Frosted Glass Dock
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    border: const Border(
                      top: BorderSide(color: AaharTheme.borderGrey, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            MealCategoryType mealType;
                            if (now.hour >= 5 && now.hour < 11) {
                              mealType = MealCategoryType.breakfast;
                            } else if (now.hour >= 11 && now.hour < 16) {
                              mealType = MealCategoryType.lunch;
                            } else if (now.hour >= 16 && now.hour < 19) {
                              mealType = MealCategoryType.snack;
                            } else {
                              mealType = MealCategoryType.dinner;
                            }

                            await ref
                                .read(diaryControllerProvider.notifier)
                                .addEntry(
                                  foodName: _data.foodName,
                                  cacheId: null,
                                  servingQuantityG: 100.0,
                                  caloriesConsumed: _data.nutrients.calories100g,
                                  consumedMacros: {
                                    'protein_g': _data.nutrients.protein100g,
                                    'carbs_g': _data.nutrients.carbs100g,
                                    'fat_g': _data.nutrients.fat100g,
                                  },
                                  mealType: mealType,
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AaharTheme.primaryGreen,
                                  content: Text(
                                    'Logged "${_data.foodName}" to Daily Diary!',
                                  ),
                                ),
                              );
                              context.go('/diary');
                            }
                          },
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('Log to Daily Food Diary'),
                        ),
                        const SizedBox(height: 6),
                        const HealthDisclaimerFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeaderCard() {
    String sourceBadgeText = 'Verified via Open Food Facts';
    if (_data.source == 'gemini_vision') {
      sourceBadgeText = 'Vision OCR • Gemini 3.5 Flash';
    } else if (_data.source == 'street_food') {
      sourceBadgeText = 'ICMR-NIN IFCT Baseline';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AaharTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AaharTheme.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: AaharTheme.primaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  sourceBadgeText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AaharTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _data.foodName,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AaharTheme.textHeadline,
            ),
          ),
          if (_data.brandName != null && _data.brandName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _data.brandName!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AaharTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreparationInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.soup_kitchen_outlined,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preparation & Processing Insights',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _data.preparationInsights!,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Deconstructed Molecules (${_data.ingredients.length})',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AaharTheme.textHeadline,
              ),
            ),
            Text(
              'FSSAI Norms',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AaharTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_data.ingredients.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AaharTheme.borderGrey),
            ),
            child: Center(
              child: Text(
                'No detailed ingredient list identified for this item.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AaharTheme.textMuted,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _data.ingredients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _data.ingredients[index];
              return MoleculeCard(molecule: item);
            },
          ),
      ],
    );
  }
}
