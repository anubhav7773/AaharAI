import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../models/food_models.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({Dio? dioOverride, AppEnv? env}) {
    _dio = dioOverride ??
        Dio(
          BaseOptions(
            baseUrl: (env ?? AppEnv.fromEnvironment()).validate().apiBaseUrl,
            connectTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
            sendTimeout: const Duration(seconds: 45),
            headers: {
              'Accept': 'application/json',
              'X-Client-Platform':
                  !kIsWeb && Platform.isAndroid ? 'android' : 'ios',
            },
          ),
        );
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('[HTTP Request] ${options.method} -> ${options.uri}');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('[HTTP Error] ${error.type} -> ${error.message}');
          }
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: _mapDioError(error),
            ),
          );
        },
      ),
    );
  }

  ApiException _mapDioError(DioException error) {
    if ({
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    }.contains(error.type)) {
      return ServerWarmingException(
        'Server is waking up. Please retry in a few seconds...',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return NetworkException();
    }


    final response = error.response;
    if (response != null) {
      final data = response.data;
      final message = data is Map<String, dynamic> && data['detail'] != null
          ? data['detail'].toString()
          : 'An unexpected server error occurred.';
      if (response.statusCode == 404) {
        return ProductNotFoundException(message);
      }
      if (response.statusCode == 502 || response.statusCode == 503) {
        return ServerWarmingException();
      }
      return ApiException(
        message: message,
        statusCode: response.statusCode,
        details: data,
      );
    }
    return ApiException(message: error.message ?? 'Unknown error occurred.');
  }

  Future<bool> warmUpServer() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<FoodItem> scanBarcode(String barcode) async {
    try {
      final response =
          await _dio.get('/api/v1/scan/barcode/${barcode.trim()}');
      return FoodItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<FoodItem> getStreetFoodAnalysis(String dishName) async {
    try {
      final response = await _dio.get(
        '/api/v1/scan/street-food',
        queryParameters: {'dish_name': dishName.trim()},
      );
      return FoodItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<FoodItem> scanLabelVision({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/scan/vision',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
        }),
      );
      return FoodItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<Map<String, dynamic>> uploadLabelImage(File imageFile) async {
    final item = await scanLabelVision(
      imageBytes: await imageFile.readAsBytes(),
      fileName: imageFile.uri.pathSegments.last,
    );
    return item.toJson();
  }

  Future<Map<String, dynamic>> fetchStreetFoodAnalysis(String dishName) async {
    final item = await getStreetFoodAnalysis(dishName);
    return item.toJson();
  }

  ApiException _apiException(DioException error) =>
      error.error is ApiException
          ? error.error as ApiException
          : ApiException(message: error.message ?? 'Unknown error occurred.');
}
