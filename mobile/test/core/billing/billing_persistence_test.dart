import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aahar_ai/core/billing/billing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File testCacheFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('aaharai_billing_test');
    testCacheFile = File('${tempDir.path}/test_entitlement.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('BillingService persists and loads cached entitlement offline', () async {
    final billing = BillingService(cacheFileOverride: testCacheFile);

    // Initial state is false
    expect(billing.isProUser.value, isFalse);

    // Persist pro = true
    await billing.persistEntitlement(true);
    expect(await testCacheFile.exists(), isTrue);

    // New instance loads cached entitlement without network store
    final freshBilling = BillingService(cacheFileOverride: testCacheFile);
    final loaded = await freshBilling.loadCachedEntitlement();

    expect(loaded, isTrue);
    expect(freshBilling.isProUser.value, isTrue);

    billing.dispose();
    freshBilling.dispose();
  });
}
