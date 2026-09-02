import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final serverWarmingProvider = FutureProvider<bool>((ref) async {
  return ref.watch(apiClientProvider).warmUpServer();
});
