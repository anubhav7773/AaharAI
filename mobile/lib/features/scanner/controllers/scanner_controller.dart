import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../analysis/models/food_analysis_model.dart';

final scannerControllerProvider =
    StateNotifierProvider<ScannerController, AsyncValue<FoodAnalysisResponse?>>(
  (ref) => ScannerController(ref.read(apiClientProvider)),
);

class ScannerController
    extends StateNotifier<AsyncValue<FoodAnalysisResponse?>> {
  final ApiClient _apiClient;

  ScannerController(this._apiClient) : super(const AsyncValue.data(null));

  Future<FoodAnalysisResponse?> processBarcode(String barcode) async {
    state = const AsyncValue.loading();
    try {
      final rawData = await _apiClient.scanBarcode(barcode);
      final analysis = FoodAnalysisResponse.fromJson(rawData);
      state = AsyncValue.data(analysis);
      return analysis;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return null;
    }
  }

  Future<FoodAnalysisResponse?> processImage(File imageFile) async {
    state = const AsyncValue.loading();
    try {
      final rawData = await _apiClient.uploadLabelImage(imageFile);
      final analysis = FoodAnalysisResponse.fromJson(rawData);
      state = AsyncValue.data(analysis);
      return analysis;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return null;
    }
  }

  Future<FoodAnalysisResponse?> processStreetFood(String dishName) async {
    state = const AsyncValue.loading();
    try {
      final rawData = await _apiClient.fetchStreetFoodAnalysis(dishName);
      final analysis = FoodAnalysisResponse.fromJson(rawData);
      state = AsyncValue.data(analysis);
      return analysis;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return null;
    }
  }
}
