import 'package:flutter_test/flutter_test.dart';
import 'package:aahar_ai/features/diary/data/diary_repository.dart';

void main() {
  group('DiaryRepository Date Range Tests', () {
    test('computeUtcDateRange accurately calculates local calendar day bounds in UTC', () {
      final localDate = DateTime(2026, 9, 3, 14, 30); // 2:30 PM local
      final (startUtc, endUtc) = DiaryRepository.computeUtcDateRange(localDate);

      // Verify bounds cover exactly 24 hours
      expect(endUtc.difference(startUtc), const Duration(days: 1));

      // Verify that local midnight is start
      final localStart = DateTime(2026, 9, 3);
      expect(startUtc, localStart.toUtc());

      // Verify that 5:00 AM local time on that day falls inside the range
      final earlyMorning = DateTime(2026, 9, 3, 5, 0).toUtc();
      expect(earlyMorning.isAfter(startUtc) || earlyMorning.isAtSameMomentAs(startUtc), isTrue);
      expect(earlyMorning.isBefore(endUtc), isTrue);

      // Verify that 11:59 PM local time on that day falls inside the range
      final lateNight = DateTime(2026, 9, 3, 23, 59).toUtc();
      expect(lateNight.isAfter(startUtc), isTrue);
      expect(lateNight.isBefore(endUtc), isTrue);

      // Verify that previous day 11:59 PM does NOT fall inside the range
      final prevDayLateNight = DateTime(2026, 9, 2, 23, 59).toUtc();
      expect(prevDayLateNight.isBefore(startUtc), isTrue);
    });
  });
}
