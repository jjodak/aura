# AGENTS.md

이 문서는 Aura 코드베이스에서 작업하는 AI/자동화 에이전트를 위한 작업 지침입니다.

## 프로젝트 개요

Aura는 Flutter 기반 메모 앱입니다. 핵심 흐름은 다음과 같습니다.

1. 사용자가 메모를 작성하거나 이미지 OCR로 텍스트를 추가합니다.
2. `MemoAiService`가 TFLite 모델과 규칙 기반 로직으로 메모 카테고리, 폴더, 일정 여부를 분석합니다.
3. 사용자는 추천 폴더와 캘린더 저장 여부를 확인합니다.
4. Firestore에 메모, 폴더, 일정이 저장되고 필요하면 로컬 알림이 예약됩니다.

## 주요 파일

- `lib/main.dart`: Firebase, 테마, 알림 초기화
- `lib/app.dart`: 앱 루트, 테마, 인증 래퍼
- `lib/core/auth/auth_wrapper.dart`: 로그인 상태 라우팅
- `lib/core/services/memo_ai_service.dart`: 메모 분류, 폴더 추천, 일정 감지
- `lib/core/services/image_text_recognition_service.dart`: 한글/영어 OCR
- `lib/core/services/notification_service.dart`: iOS/Android 로컬 알림
- `lib/features/memo/memo_page.dart`: 메모 작성, AI 저장 확인, 캘린더 저장 제안
- `lib/features/calendar/calendar_page.dart`: 캘린더 화면
- `lib/features/calendar/event_bottom_sheet.dart`: 일정 추가/수정 UI
- `model/train_memo_context_tflite.py`: 모델 학습 및 TFLite 변환
- `assets/models/memo_context_metadata.json`: 모델 설정과 검증 지표

## 작업 원칙

- 기존 Flutter/Firebase 구조를 유지하고, 화면별 책임을 크게 흔들지 않습니다.
- Firestore 경로는 `users/{uid}` 하위 컬렉션 구조를 유지합니다.
- 메모 AI 로직 변경 시 `test/widget_test.dart`에 날짜/분류 회귀 테스트를 추가합니다.
- iOS 네이티브 변경은 `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`, `ios/Podfile` 영향을 함께 확인합니다.
- 사용자가 만든 기존 변경을 임의로 되돌리지 않습니다.
- 파일 수정 후 최소한 관련 파일 `flutter analyze`와 `flutter test`를 실행합니다.

## 코딩 스타일

- Dart 코드는 `dart format`을 적용합니다.
- 이 코드베이스에는 일부 `ignore_for_file`이 존재합니다. 전역 스타일 정리는 별도 요청 없이 대규모로 수행하지 않습니다.
- 앱의 문구는 기본적으로 한국어를 사용합니다.
- UI는 현재의 둥근 카드, 테마 색상, `AppThemeColor` 패턴을 따릅니다.
- 새 공통 색상은 `lib/core/theme/app_theme.dart`에 있는 테마 값 사용을 우선합니다.

## AI 모델 관련 지침

- 앱 내 실시간 재학습은 현재 구현되어 있지 않습니다.
- 재학습은 `model/generate_memo_context_examples.py`와 `model/train_memo_context_tflite.py`로 오프라인 수행합니다.
- 앱에서 모델은 `assets/models/memo_context_classifier.tflite`와 `assets/models/memo_context_metadata.json`를 함께 사용합니다.
- TFLite 모델 교체 시 `pubspec.yaml` asset 경로와 실제 파일 존재 여부를 확인합니다.
- 모델 로딩 실패 시 fallback 키워드 분류가 동작하므로, 로딩 실패를 조용히 삼키는 현재 동작을 바꿀 때는 사용자 경험을 고려합니다.
- 일정 감지는 모델 결과만으로 결정하지 않고, `MemoAiService`의 날짜/시간/키워드 규칙을 함께 봅니다.

## OCR 관련 지침

- OCR은 Google ML Kit의 Korean/Latin text recognizer를 동시에 사용합니다.
- OCR 관련 변경 시 iOS 권한 문구(`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`)와 Android 권한을 함께 확인합니다.
- Google MLKit Pod는 Apple Silicon iOS 26+ 시뮬레이터 arm64 경고를 출력할 수 있습니다. 실제 iPhone 동작 여부를 별도로 확인합니다.

## iOS/Firebase 주의사항

- Firebase 초기화는 Dart의 `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`에서 수행합니다.
- `AppDelegate.swift`에 `FirebaseApp.configure()`를 다시 추가하지 않습니다. 중복 초기화는 실행 직후 네이티브 크래시 원인이 될 수 있습니다.
- `AppDelegate.swift`는 알림 delegate와 배지 MethodChannel 설정만 담당합니다.
- 실제 iPhone 실행 확인은 `flutter run -d <device-id>`로 합니다.

## 권장 검증 명령

전체 분석:

```bash
flutter analyze
```

전체 테스트:

```bash
flutter test
```

iOS 디버그 빌드:

```bash
flutter build ios --debug --no-codesign
```

모델 재학습:

```bash
python3 model/generate_memo_context_examples.py
python3 model/train_memo_context_tflite.py
```

## 자주 깨지는 영역

- 자연어 날짜 파싱: `이번주`, `다음주`, 요일 기준 계산은 현재 날짜에 따라 회귀가 생기기 쉽습니다.
- 일정 저장: 체크박스 상태, 일정 제목, 시작/종료 시간, 알림 값이 Firestore 저장 조건과 일치해야 합니다.
- 폴더 삭제: 메모가 있는 폴더 삭제 시 `임시 폴더` 이동과 count 갱신을 같이 봐야 합니다.
- 알림: 일정 수정 시 기존 알림 취소 후 새 알림 예약이 필요합니다.
- iOS 실행: Firebase 중복 초기화, Pod 변경, MLKit 네이티브 의존성 문제를 구분해서 봐야 합니다.

## 문서 업데이트 기준

기능, 데이터 구조, 모델 학습 방식, 실행 방법이 바뀌면 `README.md`를 함께 업데이트합니다. 에이전트가 반복해서 알아야 하는 주의사항이나 작업 규칙이 생기면 이 파일에 반영합니다.
