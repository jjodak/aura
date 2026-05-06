import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MemoFolderCandidate {
  final String id;
  final String name;
  final int colorValue;

  const MemoFolderCandidate({
    required this.id,
    required this.name,
    required this.colorValue,
  });
}

class MemoFolderSuggestion {
  final String? folderId;
  final String name;
  final int colorValue;
  final bool isNew;
  final double confidence;

  const MemoFolderSuggestion({
    required this.folderId,
    required this.name,
    required this.colorValue,
    required this.isNew,
    required this.confidence,
  });
}

class MemoScheduleIntent {
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final double confidence;

  const MemoScheduleIntent({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });
}

class MemoAiAnalysis {
  final String category;
  final double categoryConfidence;
  final Map<String, double> categoryScores;
  final MemoFolderSuggestion folder;
  final MemoScheduleIntent? schedule;

  const MemoAiAnalysis({
    required this.category,
    required this.categoryConfidence,
    required this.categoryScores,
    required this.folder,
    required this.schedule,
  });
}

class MemoAiService {
  static const String _modelAssetPath =
      'assets/models/memo_context_classifier.tflite';
  static const String _metadataAssetPath =
      'assets/models/memo_context_metadata.json';
  _MemoTextClassifier? _classifier;

  Future<MemoAiAnalysis> analyze({
    required String content,
    required DateTime now,
    required List<MemoFolderCandidate> folders,
  }) async {
    final classifier = await _loadClassifier();
    final schedule = _detectSchedule(content, now);
    final categoryScores = classifier.classify(content);
    var category = _bestLabel(categoryScores);

    if (schedule != null && schedule.confidence >= 0.68) {
      category = '일정';
    }

    final folder = _suggestFolder(
      content: content,
      category: category,
      categoryConfidence: categoryScores[category] ?? 0.5,
      folders: folders,
      classifier: classifier,
    );

    return MemoAiAnalysis(
      category: category,
      categoryConfidence: categoryScores[category] ?? 0.5,
      categoryScores: categoryScores,
      folder: folder,
      schedule: schedule,
    );
  }

  Future<_MemoTextClassifier> _loadClassifier() async {
    if (_classifier != null) return _classifier!;

    try {
      final raw = await rootBundle.loadString(_metadataAssetPath);
      final metadata = _MemoModelMetadata.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final interpreter = await Interpreter.fromAsset(_modelAssetPath);
      _classifier = _MemoTextClassifier.tflite(metadata, interpreter);
    } catch (_) {
      _classifier = _MemoTextClassifier.fallback();
    }
    return _classifier!;
  }

  MemoFolderSuggestion _suggestFolder({
    required String content,
    required String category,
    required double categoryConfidence,
    required List<MemoFolderCandidate> folders,
    required _MemoTextClassifier classifier,
  }) {
    MemoFolderCandidate? bestFolder;
    var bestScore = 0.0;
    final normalizedText = _normalize(content);
    final categoryTerms = _folderTerms(category);

    for (final folder in folders) {
      if (folder.name == '임시 폴더') continue;

      var score = 0.0;
      final normalizedFolder = _normalize(folder.name);
      if (normalizedFolder == _normalize(category)) score += 8;
      if (normalizedFolder.contains(_normalize(category)) ||
          _normalize(category).contains(normalizedFolder)) {
        score += 5;
      }
      if (normalizedText.contains(normalizedFolder)) score += 4;

      for (final term in categoryTerms) {
        if (normalizedFolder.contains(_normalize(term))) score += 2;
      }

      if (score > bestScore) {
        bestScore = score;
        bestFolder = folder;
      }
    }

    if (bestFolder != null && bestScore >= 2) {
      return MemoFolderSuggestion(
        folderId: bestFolder.id,
        name: bestFolder.name,
        colorValue: bestFolder.colorValue,
        isNew: false,
        confidence: math.max(categoryConfidence, 0.72),
      );
    }

    final colorValue =
        classifier.folderColors[category] ??
        classifier.folderColors['개인'] ??
        0xFF588157;
    return MemoFolderSuggestion(
      folderId: null,
      name: category,
      colorValue: colorValue,
      isNew: true,
      confidence: categoryConfidence,
    );
  }

  MemoScheduleIntent? _detectSchedule(String text, DateTime now) {
    final normalizedText = _normalize(text);
    final hasScheduleKeyword = _scheduleKeywords.any(
      (keyword) => normalizedText.contains(_normalize(keyword)),
    );
    final dateMatch = _extractDate(text, now);
    final timeMatch = _extractTime(text);

    if (dateMatch == null && timeMatch == null) return null;
    if (!hasScheduleKeyword && !(dateMatch != null && timeMatch != null)) {
      return null;
    }

    var date = dateMatch?.date ?? DateTime(now.year, now.month, now.day);
    var hour = timeMatch?.hour ?? _defaultHour(text);
    final minute = timeMatch?.minute ?? 0;

    var start = DateTime(date.year, date.month, date.day, hour, minute);
    if (dateMatch == null && start.isBefore(now)) {
      final tomorrow = now.add(const Duration(days: 1));
      start = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        hour,
        minute,
      );
    }

    final end = start.add(_guessDuration(text));
    var confidence = 0.55;
    if (hasScheduleKeyword) confidence += 0.2;
    if (dateMatch != null) confidence += 0.15;
    if (timeMatch != null) confidence += 0.1;

    final hasDiaryKeyword = [
      '일기',
      '기분',
      '다짐',
      '감정',
      '생각',
      '하루',
      '기록',
    ].any((keyword) => normalizedText.contains(_normalize(keyword)));
    if (hasDiaryKeyword && !hasScheduleKeyword) {
      confidence -= 0.3;
    }

    return MemoScheduleIntent(
      title: _makeScheduleTitle(text),
      startTime: start,
      endTime: end,
      confidence: confidence.clamp(0.0, 0.98).toDouble(),
    );
  }

  _DateMatch? _extractDate(String text, DateTime now) {
    final normalizedText = _normalize(text);
    final today = DateTime(now.year, now.month, now.day);

    if (normalizedText.contains('오늘')) {
      return _DateMatch(today);
    }
    if (normalizedText.contains('내일')) {
      return _DateMatch(today.add(const Duration(days: 1)));
    }
    if (normalizedText.contains('모레')) {
      return _DateMatch(today.add(const Duration(days: 2)));
    }
    if (normalizedText.contains('다음주말')) {
      final daysUntilSaturday = (DateTime.saturday - now.weekday + 7) % 7;
      return _DateMatch(
        today.add(
          Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday + 7),
        ),
      );
    }
    if (normalizedText.contains('이번주말') || normalizedText.contains('주말')) {
      final daysUntilSaturday = (DateTime.saturday - now.weekday + 7) % 7;
      return _DateMatch(
        today.add(
          Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
        ),
      );
    }

    final yearMonthDay = RegExp(
      r'(\d{4})\s*년\s*(\d{1,2})\s*월\s*(\d{1,2})\s*일?',
    ).firstMatch(text);
    if (yearMonthDay != null) {
      return _safeDate(
        int.parse(yearMonthDay.group(1)!),
        int.parse(yearMonthDay.group(2)!),
        int.parse(yearMonthDay.group(3)!),
      );
    }

    final dotted = RegExp(
      r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})',
    ).firstMatch(text);
    if (dotted != null) {
      return _safeDate(
        int.parse(dotted.group(1)!),
        int.parse(dotted.group(2)!),
        int.parse(dotted.group(3)!),
      );
    }

    final monthDay = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일?').firstMatch(text);
    if (monthDay != null) {
      final month = int.parse(monthDay.group(1)!);
      final day = int.parse(monthDay.group(2)!);
      var match = _safeDate(now.year, month, day);
      if (match != null && match.date.isBefore(today)) {
        match = _safeDate(now.year + 1, month, day);
      }
      return match;
    }

    final relativeMonthDay = RegExp(
      r'(이번\s*달|다음\s*달)\s*(\d{1,2})\s*일?',
    ).firstMatch(text);
    if (relativeMonthDay != null) {
      final prefix = relativeMonthDay.group(1)!;
      final day = int.parse(relativeMonthDay.group(2)!);
      final monthOffset = prefix.contains('다음') ? 1 : 0;
      final base = DateTime(now.year, now.month + monthOffset, 1);
      var match = _safeDate(base.year, base.month, day);
      if (match != null && monthOffset == 0 && match.date.isBefore(today)) {
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        match = _safeDate(nextMonth.year, nextMonth.month, day);
      }
      return match;
    }

    final relativeMonth = RegExp(r'(이번\s*달|다음\s*달)').firstMatch(text);
    if (relativeMonth != null) {
      final monthOffset = relativeMonth.group(1)!.contains('다음') ? 1 : 0;
      final target = DateTime(now.year, now.month + monthOffset, 1);
      return _DateMatch(DateTime(target.year, target.month, target.day));
    }

    final weekdayMatch = RegExp(
      r'(이번\s*주|다음\s*주|이번|다음)?\s*(월요일|화요일|수요일|목요일|금요일|토요일|일요일)',
    ).firstMatch(text);
    if (weekdayMatch != null) {
      final targetWeekday = _weekdays[weekdayMatch.group(2)!]!;
      final prefix = weekdayMatch.group(1) ?? '';

      if (prefix.contains('이번')) {
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return _DateMatch(startOfWeek.add(Duration(days: targetWeekday - 1)));
      }

      if (prefix.contains('다음')) {
        final startOfNextWeek = today.add(Duration(days: 8 - now.weekday));
        return _DateMatch(
          startOfNextWeek.add(Duration(days: targetWeekday - 1)),
        );
      }

      var daysUntil = (targetWeekday - now.weekday + 7) % 7;
      if (daysUntil == 0) daysUntil = 7;
      return _DateMatch(today.add(Duration(days: daysUntil)));
    }

    return null;
  }

  _DateMatch? _safeDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return _DateMatch(date);
  }

  _TimeMatch? _extractTime(String text) {
    final koreanTime = RegExp(
      r'(오전|오후|아침|저녁|밤)?\s*(\d{1,2})\s*(?:시|:)\s*(?:(\d{1,2})\s*분?)?',
    ).firstMatch(text);

    if (koreanTime != null) {
      final marker = koreanTime.group(1) ?? '';
      var hour = int.parse(koreanTime.group(2)!);
      final minute = int.tryParse(koreanTime.group(3) ?? '0') ?? 0;

      if ((marker == '오후' || marker == '저녁' || marker == '밤') && hour < 12) {
        hour += 12;
      }
      if ((marker == '오전' || marker == '아침') && hour == 12) {
        hour = 0;
      }

      if (hour <= 23 && minute <= 59) {
        return _TimeMatch(hour, minute);
      }
    }

    final englishTime = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
      caseSensitive: false,
    ).firstMatch(text);

    if (englishTime != null) {
      var hour = int.parse(englishTime.group(1)!);
      final minute = int.tryParse(englishTime.group(2) ?? '0') ?? 0;
      final marker = englishTime.group(3)!.toLowerCase();

      if (marker == 'pm' && hour < 12) hour += 12;
      if (marker == 'am' && hour == 12) hour = 0;
      if (hour <= 23 && minute <= 59) {
        return _TimeMatch(hour, minute);
      }
    }

    return null;
  }

  int _defaultHour(String text) {
    final normalizedText = _normalize(text);
    if (normalizedText.contains('마감') ||
        normalizedText.contains('제출') ||
        normalizedText.contains('까지')) {
      return 18;
    }
    if (normalizedText.contains('아침')) return 9;
    if (normalizedText.contains('점심')) return 12;
    if (normalizedText.contains('저녁')) return 19;
    return 9;
  }

  Duration _guessDuration(String text) {
    final normalizedText = _normalize(text);
    if (normalizedText.contains('마감') ||
        normalizedText.contains('제출') ||
        normalizedText.contains('까지')) {
      return const Duration(minutes: 30);
    }
    if (normalizedText.contains('수업') || normalizedText.contains('강의')) {
      return const Duration(hours: 2);
    }
    return const Duration(hours: 1);
  }

  String _makeScheduleTitle(String text) {
    var title = text.split('\n').first.trim();
    title = title
        .replaceAll(RegExp(r'\d{4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일?'), '')
        .replaceAll(RegExp(r'\d{4}[./-]\d{1,2}[./-]\d{1,2}'), '')
        .replaceAll(RegExp(r'\d{1,2}\s*월\s*\d{1,2}\s*일?'), '')
        .replaceAll(
          RegExp(r'(이번\s*주|다음\s*주|이번|다음)?\s*(월요일|화요일|수요일|목요일|금요일|토요일|일요일)'),
          '',
        )
        .replaceAll(RegExp(r'(오늘|내일|모레|이번\s*달|다음\s*달|이번\s*주말|다음\s*주말|주말)'), '')
        .replaceAll(
          RegExp(r'(오전|오후|아침|저녁|밤)?\s*\d{1,2}\s*(?:시|:)\s*\d{0,2}\s*분?'),
          '',
        )
        .replaceAll(RegExp(r'(오전|오후|아침|점심|저녁|밤)'), '')
        .replaceAll(RegExp(r'병원\s*가기'), '병원 방문')
        .replaceAll(RegExp(r'치과\s*가기'), '치과 방문')
        .replaceAll(RegExp(r'(까지|예약|일정)$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (title.isEmpty) return '메모 일정';
    if (title == '병원가기') return '병원 방문';
    if (title == '치과가기') return '치과 방문';
    if (title == '병원' || title.endsWith('병원')) return '$title 방문';
    if (title == '치과' || title.endsWith('치과')) return '$title 방문';
    if (title.endsWith('회의')) return title;
    if (title.endsWith('미팅')) return title;
    if (title.endsWith('약속')) return title;
    if (title.length > 36) return '${title.substring(0, 36)}...';
    return title;
  }

  String _bestLabel(Map<String, double> scores) {
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<String> _folderTerms(String category) {
    return switch (category) {
      '일정' => ['일정', '약속', '회의', '캘린더', '예약', '마감', '스케줄', '일과', '모임', '플랜'],
      '할 일' => [
        '할일',
        '할 일',
        '체크',
        '해야',
        'todo',
        'task',
        '목록',
        '투두',
        '과업',
        '정리',
      ],
      '아이디어' => ['아이디어', '생각', '기획', '컨셉', '영감', '구상', '브레인스토밍', '기발', '번뜩'],
      '공부' => ['공부', '학습', '강의', '과제', '시험', '스터디', '인강', '수업', '배움', '독서'],
      '업무' => ['업무', '회사', '프로젝트', '회의', '메일', '보고', '직장', '출근', '기획안', '업무용'],
      '건강' => ['건강', '운동', '병원', '약', '식단', '헬스', '다이어트', '병원', '진료', '체력'],
      '여행' => ['여행', '항공', '호텔', '여권', '숙소', '휴가', '관광', '투어', '비행기', '맛집'],
      '재정' => ['재정', '돈', '결제', '예산', '지출', '가계부', '월급', '저축', '통장', '비용'],
      '일기' => ['일기', '감정', '다짐', '하루', '기록', '느낌', '마음', '소회', '감상'],
      _ => ['개인', '메모', '기록', '생각', '나의', '기억', '사적인'],
    };
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^가-힣a-z0-9]'), '');
  }

  static const _scheduleKeywords = [
    '일정',
    '약속',
    '회의',
    '미팅',
    '수업',
    '강의',
    '예약',
    '병원',
    '치과',
    '면접',
    '마감',
    '제출',
    '까지',
    '세미나',
    '워크숍',
    'deadline',
    'meeting',
    'appointment',
  ];

  static const _weekdays = {
    '월요일': DateTime.monday,
    '화요일': DateTime.tuesday,
    '수요일': DateTime.wednesday,
    '목요일': DateTime.thursday,
    '금요일': DateTime.friday,
    '토요일': DateTime.saturday,
    '일요일': DateTime.sunday,
  };
}

class _MemoTextClassifier {
  final _MemoModelMetadata metadata;
  final Interpreter? _interpreter;

  const _MemoTextClassifier._(this.metadata, this._interpreter);

  factory _MemoTextClassifier.tflite(
    _MemoModelMetadata metadata,
    Interpreter interpreter,
  ) {
    return _MemoTextClassifier._(metadata, interpreter);
  }

  factory _MemoTextClassifier.fallback() {
    return _MemoTextClassifier._(_MemoModelMetadata.fallback(), null);
  }

  List<String> get labels => metadata.labels;
  Map<String, int> get folderColors => metadata.folderColors;

  Map<String, double> classify(String text) {
    if (_interpreter == null) {
      return _keywordScores(text);
    }

    try {
      final input = [_vectorize(text)];
      final output = [List<double>.filled(metadata.labels.length, 0)];
      _interpreter.run(input, output);
      return {
        for (var i = 0; i < metadata.labels.length; i++)
          metadata.labels[i]: output.first[i],
      };
    } catch (_) {
      return _keywordScores(text);
    }
  }

  Float32List _vectorize(String text) {
    final normalized = _normalize(text);
    final vector = Float32List(metadata.featureSize);

    for (var n = metadata.ngramMin; n <= metadata.ngramMax; n++) {
      if (normalized.length < n) continue;
      for (var start = 0; start <= normalized.length - n; start++) {
        final ngram = normalized.substring(start, start + n);
        final bucket = _fnv1a(ngram) % metadata.featureSize;
        vector[bucket] += 1;
      }
    }

    final total = vector.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return vector;

    final denominator = math.log(total + 1);
    for (var i = 0; i < vector.length; i++) {
      vector[i] = math.log(vector[i] + 1) / denominator;
    }
    return vector;
  }

  Map<String, double> _keywordScores(String text) {
    final normalizedText = _normalize(text);
    final scores = <String, double>{};

    for (final label in metadata.labels) {
      var score = math.log(1 / metadata.labels.length);
      final keywordWeights = metadata.keywordWeights[label] ?? const {};

      for (final entry in keywordWeights.entries) {
        if (normalizedText.contains(_normalize(entry.key))) {
          score += entry.value;
        }
      }

      scores[label] = score;
    }

    final maxScore = scores.values.reduce(math.max);
    final expScores = scores.map(
      (label, score) => MapEntry(label, math.exp(score - maxScore)),
    );
    final total = expScores.values.fold<double>(0, (sum, value) => sum + value);
    return expScores.map((label, score) => MapEntry(label, score / total));
  }

  int _fnv1a(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^가-힣a-z0-9]'), '');
  }
}

class _MemoModelMetadata {
  final List<String> labels;
  final int featureSize;
  final int ngramMin;
  final int ngramMax;
  final Map<String, Map<String, double>> keywordWeights;
  final Map<String, int> folderColors;

  const _MemoModelMetadata({
    required this.labels,
    required this.featureSize,
    required this.ngramMin,
    required this.ngramMax,
    required this.keywordWeights,
    required this.folderColors,
  });

  factory _MemoModelMetadata.fromJson(Map<String, dynamic> json) {
    return _MemoModelMetadata(
      labels: (json['labels'] as List)
          .map((value) => value.toString())
          .toList(),
      featureSize: (json['featureSize'] as num?)?.toInt() ?? 512,
      ngramMin: (json['ngramMin'] as num?)?.toInt() ?? 1,
      ngramMax: (json['ngramMax'] as num?)?.toInt() ?? 3,
      keywordWeights: _nestedDoubleMap(json['keywordWeights']),
      folderColors: (json['folderColors'] as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
    );
  }

  factory _MemoModelMetadata.fallback() {
    const labels = [
      '일정',
      '할 일',
      '아이디어',
      '공부',
      '업무',
      '건강',
      '여행',
      '재정',
      '개인',
      '일기',
    ];

    return _MemoModelMetadata(
      labels: labels,
      featureSize: 512,
      ngramMin: 1,
      ngramMax: 3,
      keywordWeights: const {
        '일정': {
          '일정': 2.4,
          '회의': 2.2,
          '약속': 2.0,
          '예약': 2.0,
          '수업': 1.8,
          '마감': 1.8,
        },
        '할 일': {'해야': 2.0, '할일': 2.0, '구매': 1.6, '확인': 1.4, '정리': 1.3},
        '아이디어': {'아이디어': 2.2, '기획': 1.8, '컨셉': 1.7, '생각': 1.4},
        '공부': {'공부': 2.2, '과제': 1.9, '시험': 1.8, '강의': 1.5},
        '업무': {'업무': 2.0, '회사': 1.8, '프로젝트': 1.8, '보고서': 1.6, '메일': 1.4},
        '건강': {'건강': 2.0, '운동': 1.9, '병원': 1.8, '약': 1.4},
        '여행': {'여행': 2.1, '항공': 1.8, '호텔': 1.8, '여권': 1.6},
        '재정': {'결제': 1.9, '예산': 1.8, '지출': 1.8, '세금': 1.6},
        '개인': {'기분': 1.6, '가족': 1.3, '하루': 1.5, '기록': 1.5, '생각': 1.4},
        '일기': {'일기': 2.0, '감정': 1.6, '다짐': 1.5, '하루': 1.4, '기록': 1.3},
      },
      folderColors: const {
        '일정': 0xFF219EBC,
        '할 일': 0xFFE9C46A,
        '아이디어': 0xFFE56B6F,
        '공부': 0xFF6D597A,
        '업무': 0xFF457B9D,
        '건강': 0xFF588157,
        '여행': 0xFF2A9D8F,
        '재정': 0xFFD4A373,
        '개인': 0xFF8D99AE,
        '일기': 0xFFB5838D,
      },
    );
  }

  static Map<String, double> _doubleMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), (mapValue as num).toDouble()),
    );
  }

  static Map<String, Map<String, double>> _nestedDoubleMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, mapValue) {
      return MapEntry(key.toString(), _doubleMap(mapValue));
    });
  }
}

class _DateMatch {
  final DateTime date;

  const _DateMatch(this.date);
}

class _TimeMatch {
  final int hour;
  final int minute;

  const _TimeMatch(this.hour, this.minute);
}
