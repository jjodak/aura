import 'package:flutter_test/flutter_test.dart';

import 'package:aura/core/services/memo_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'detects schedule memo and matches an existing schedule folder',
    () async {
      final service = MemoAiService();

      final analysis = await service.analyze(
        content: '내일 오후 3시 강남에서 회의',
        now: DateTime(2026, 4, 30, 10),
        folders: const [
          MemoFolderCandidate(
            id: 'schedule-folder',
            name: '일정',
            colorValue: 0xFF219EBC,
          ),
        ],
      );

      expect(analysis.category, '일정');
      expect(analysis.folder.folderId, 'schedule-folder');
      expect(analysis.schedule, isNotNull);
      expect(analysis.schedule!.startTime, DateTime(2026, 5, 1, 15));
    },
  );

  test(
    'suggests a new contextual folder when no matching folder exists',
    () async {
      final service = MemoAiService();

      final analysis = await service.analyze(
        content: '제주 여행 항공권 확인하고 호텔 예약 번호 메모',
        now: DateTime(2026, 4, 30, 10),
        folders: const [],
      );

      expect(analysis.folder.isNew, isTrue);
      expect(analysis.folder.name, '여행');
    },
  );

  test('detects relative month schedule date', () async {
    final service = MemoAiService();

    final analysis = await service.analyze(
      content: '다음 달 1일 오후 2시 병원 예약',
      now: DateTime(2026, 4, 30, 10),
      folders: const [],
    );

    expect(analysis.category, '일정');
    expect(analysis.schedule, isNotNull);
    expect(analysis.schedule!.startTime, DateTime(2026, 5, 1, 14));
  });

  test('detects this week weekday schedule date', () async {
    final service = MemoAiService();

    final analysis = await service.analyze(
      content: '이번주 수요일 오후 3시 회의',
      now: DateTime(2026, 4, 27, 10),
      folders: const [],
    );

    expect(analysis.category, '일정');
    expect(analysis.schedule, isNotNull);
    expect(analysis.schedule!.startTime, DateTime(2026, 4, 29, 15));
  });

  test('detects next week weekday schedule date', () async {
    final service = MemoAiService();

    final analysis = await service.analyze(
      content: '다음주 금요일 오전 10시 병원 예약',
      now: DateTime(2026, 4, 27, 10),
      folders: const [],
    );

    expect(analysis.category, '일정');
    expect(analysis.schedule, isNotNull);
    expect(analysis.schedule!.startTime, DateTime(2026, 5, 8, 10));
  });

  test('detects next week Monday from Friday as the coming Monday', () async {
    final service = MemoAiService();

    final analysis = await service.analyze(
      content: '다음주 월요일 오전 병원가기',
      now: DateTime(2026, 5, 1, 10),
      folders: const [],
    );

    expect(analysis.category, '일정');
    expect(analysis.schedule, isNotNull);
    expect(analysis.schedule!.startTime, DateTime(2026, 5, 4, 9));
    expect(analysis.schedule!.title, '병원 방문');
  });

  test('makes a natural schedule title from date words', () async {
    final service = MemoAiService();

    final analysis = await service.analyze(
      content: '다음주 월요일 병원',
      now: DateTime(2026, 5, 1, 10),
      folders: const [],
    );

    expect(analysis.schedule, isNotNull);
    expect(analysis.schedule!.title, '병원 방문');
  });

  test('detects bare weekday as the next matching weekday', () async {
    final service = MemoAiService();

    final analysis = await service.analyze(
      content: '금요일 오후 6시 친구 약속',
      now: DateTime(2026, 4, 27, 10),
      folders: const [],
    );

    expect(analysis.category, '일정');
    expect(analysis.schedule, isNotNull);
    expect(analysis.schedule!.startTime, DateTime(2026, 5, 1, 18));
  });
}
