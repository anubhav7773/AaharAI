import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aahar_ai/core/models/food_models.dart';
import 'package:aahar_ai/core/network/api_client.dart';
import 'package:aahar_ai/core/network/api_exceptions.dart';

class MockAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  late MockAdapter mockAdapter;
  late ApiClient apiClient;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    mockAdapter = MockAdapter();
    dio.httpClientAdapter = mockAdapter;
    apiClient = ApiClient(dioOverride: dio);
  });

  test('warmUpServer returns true for health 200', () async {
    mockAdapter.handler = (_) => ResponseBody.fromString(
          '{"status":"healthy"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    expect(await apiClient.warmUpServer(), isTrue);
  });

  test('scanBarcode maps 404 to ProductNotFoundException', () async {
    mockAdapter.handler = (_) => ResponseBody.fromString(
          '{"detail":"Barcode not found"}',
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    expect(
      () => apiClient.scanBarcode('9999999999999'),
      throwsA(isA<ProductNotFoundException>()),
    );
  });

  test('scanBarcode deserializes a food response', () async {
    mockAdapter.handler = (_) => ResponseBody.fromString(
          '{"food_name":"Poha","source":"street_food","nutrients":{"calories":250,"protein_g":5,"carbs_g":40,"fat_g":8}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    final item = await apiClient.scanBarcode('123');
    expect(item, isA<FoodItem>());
    expect(item.foodName, 'Poha');
  });
}
