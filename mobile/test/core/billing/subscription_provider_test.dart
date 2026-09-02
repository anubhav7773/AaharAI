import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aahar_ai/core/billing/billing_service.dart';
import 'package:aahar_ai/core/billing/subscription_provider.dart';

class MockBillingService extends BillingService {
  @override
  Future<void> initialize() async {
    isProUser.value = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('isProUserProvider reflects the billing entitlement', () async {
    final mock = MockBillingService();
    await mock.initialize();
    final container = ProviderContainer(
      overrides: [billingServiceProvider.overrideWithValue(mock)],
    );

    expect(await container.read(isProUserProvider.future), isTrue);
    container.dispose();
    mock.dispose();
  });
}
