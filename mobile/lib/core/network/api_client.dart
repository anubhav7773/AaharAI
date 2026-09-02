import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_env.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(AppEnv.fromEnvironment().validate()),
);

class ApiClient {
  late final Dio dio;

  ApiClient([AppEnv? env]) {
    final appEnv = (env ?? AppEnv.fromEnvironment()).validate();
    dio = Dio(
      BaseOptions(
        baseUrl: appEnv.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 25), // Cold Gemini inference buffer
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'AaharAi-Mobile/1.0 (founder@asiverticals.me)',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          // Automatic 1-time retry for Render spin-up delays or 503 drops
          if (err.type == DioExceptionType.connectionTimeout ||
              err.response?.statusCode == 503 ||
              err.response?.statusCode == 504) {
            try {
              final response = await dio.request(
                err.requestOptions.path,
                options: Options(
                  method: err.requestOptions.method,
                  headers: err.requestOptions.headers,
                ),
                data: err.requestOptions.data,
                queryParameters: err.requestOptions.queryParameters,
              );
              return handler.resolve(response);
            } catch (_) {}
          }
          return handler.next(err);
        },
      ),
    );
  }

  Future<void> warmUpServer() async {
    try {
      await dio.get('/health');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    final res = await dio.get('/api/v1/scan/barcode/$barcode');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadLabelImage(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'ingredient_label.jpg',
      ),
    });
    final res = await dio.post('/api/v1/scan/vision', data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchStreetFoodAnalysis(String dishName) async {
    final res = await dio.get(
      '/api/v1/scan/street-food',
      queryParameters: {'dish_name': dishName},
    );
    return res.data as Map<String, dynamic>;
  }
}
