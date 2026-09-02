import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/food_models.dart';
import '../../../core/network/network_providers.dart';

class StreetFoodCategory {
  final String id;
  final String label;
  final List<String> popularDishes;

  const StreetFoodCategory({
    required this.id,
    required this.label,
    required this.popularDishes,
  });
}

const kStreetFoodCategories = <StreetFoodCategory>[
  StreetFoodCategory(
    id: 'all',
    label: 'All Popular',
    popularDishes: [
      'Veg Steamed Momo',
      'Samosa',
      'Chowmein',
      'Pani Puri',
      'Masala Dosa',
      'Chole Bhature',
    ],
  ),
  StreetFoodCategory(
    id: 'tibetan',
    label: 'Momos & Dumplings',
    popularDishes: [
      'Veg Steamed Momo',
      'Paneer Fried Momo',
      'Chicken Steamed Momo',
      'Momo Chutney',
    ],
  ),
  StreetFoodCategory(
    id: 'indo_chinese',
    label: 'Indo-Chinese',
    popularDishes: [
      'Veg Hakka Noodles',
      'Chili Paneer Dry',
      'Manchurian Gravy',
      'Fried Rice',
    ],
  ),
  StreetFoodCategory(
    id: 'chaat_fried',
    label: 'Chaat & Fried',
    popularDishes: [
      'Aloo Samosa',
      'Pani Puri (6 pcs)',
      'Sev Puri',
      'Kachori',
      'Bread Pakora',
    ],
  ),
  StreetFoodCategory(
    id: 'south_indian',
    label: 'South Indian Tiffin',
    popularDishes: ['Masala Dosa', 'Idli Sambhar', 'Medu Vada', 'Uttapam'],
  ),
];

class StreetFoodState {
  final String selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final FoodItem? activeDishAnalysis;

  const StreetFoodState({
    this.selectedCategory = 'all',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.activeDishAnalysis,
  });

  StreetFoodState copyWith({
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    FoodItem? activeDishAnalysis,
  }) {
    return StreetFoodState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeDishAnalysis: activeDishAnalysis ?? this.activeDishAnalysis,
    );
  }
}

class StreetFoodController extends StateNotifier<StreetFoodState> {
  final Ref _ref;

  StreetFoodController(this._ref) : super(const StreetFoodState());

  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategory: categoryId);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<FoodItem?> fetchDishAnalysis(String dishName) async {
    state = state.copyWith(isLoading: true);
    try {
      final item = await _ref.read(apiClientProvider).getStreetFoodAnalysis(
            dishName.trim(),
          );
      state = state.copyWith(isLoading: false, activeDishAnalysis: item);
      return item;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      return null;
    }
  }
}

final streetFoodControllerProvider =
    StateNotifierProvider<StreetFoodController, StreetFoodState>(
  (ref) => StreetFoodController(ref),
);
