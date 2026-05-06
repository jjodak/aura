# Aura

Aura는 메모를 작성하면 AI가 문맥을 분석해 저장 폴더를 추천하고, 일정으로 판단되는 메모는 캘린더 일정으로도 저장할 수 있는 Flutter 앱입니다. Firebase 기반 인증/데이터 저장, 로컬 알림, 이미지 OCR, TensorFlow Lite 메모 분류 모델을 함께 사용합니다.

## 주요 기능

- 이메일 기반 로그인, 회원가입, 비밀번호 재설정
- 메모 작성 및 폴더별 저장
- TensorFlow Lite 기반 메모 카테고리 분류
- 기존 폴더 매칭 또는 새 폴더 추천
- 일정 표현 자동 감지 및 캘린더 저장 제안
- 오늘, 내일, 모레, 이번 주/다음 주 요일, 월/일, 시간 표현 일부 자동 인식
- 일정 저장 시 제목, 시작/종료 시간, 알림 편집
- 같은 날짜 기존 일정과 시간이 겹치면 경고 표시
- 이미지에서 한글/영어 텍스트 OCR 후 메모에 삽입
- 캘린더에서 일정 추가, 수정, 삭제 및 로컬 알림 설정
- 테마 선택 및 저장
- 휴지통, 폴더 관리, 프로필/설정 화면

## 기술 스택

- Flutter / Dart
- Firebase Auth
- Cloud Firestore
- flutter_local_notifications
- Google ML Kit Text Recognition
- TensorFlow Lite (`tflite_flutter`)
- table_calendar
- shared_preferences

## 앱 구조

```text
lib/
  main.dart                         앱 초기화 진입점
  app.dart                          MaterialApp, 테마, 인증 래퍼 연결
  firebase_options.dart             FlutterFire 설정
  core/
    auth/auth_wrapper.dart           로그인 상태에 따른 화면 분기
    services/
      memo_ai_service.dart           TFLite 분류, 폴더 추천, 일정 감지
      image_text_recognition_service.dart  한글/영어 OCR
      notification_service.dart      로컬 알림, 배지 초기화
    theme/app_theme.dart             앱 테마 정의 및 저장
    widgets/                         공통 위젯
  features/
    auth/                            로그인, 회원가입, 비밀번호 찾기
    memo/                            메모 작성, AI 저장 확인, 메모 수정
    folder/                          폴더 목록, 폴더 상세
    calendar/                        캘린더, 일정 추가/수정
    profile/                         프로필
    settings/                        계정, 알림, 백업/복원, 도움말
    trash/                           휴지통

model/
  generate_memo_context_examples.py  학습 데이터 생성
  train_memo_context_tflite.py       TensorFlow 학습 및 TFLite 변환
  data/                              학습/시드 데이터

assets/models/
  memo_context_classifier.tflite     앱에 포함되는 분류 모델
  memo_context_metadata.json         라벨, 벡터화 설정, 검증 지표
```

## AI 분류 모델

메모 분류는 `assets/models/memo_context_classifier.tflite`를 사용합니다. 모델은 문자 n-gram을 해시 벡터로 바꾼 뒤 Dense 레이어로 카테고리를 예측합니다.

현재 카테고리:

- 일정
- 할 일
- 아이디어
- 공부
- 업무
- 건강
- 여행
- 재정
- 개인
- 일기

현재 메타데이터 기준 학습 데이터는 총 6,000개이며, 15%를 검증용으로 분리합니다. `assets/models/memo_context_metadata.json`에는 학습/검증 개수, 검증 정확도, 카테고리별 정확도가 기록됩니다.

모델 로딩에 실패하면 `memo_ai_service.dart`의 키워드 기반 fallback 분류가 동작합니다.

## OCR 처리

OCR은 `google_mlkit_text_recognition`을 사용합니다. `ImageTextRecognitionService`가 Korean recognizer와 Latin recognizer를 모두 실행한 뒤 중복 라인을 제거해 메모 본문에 추가합니다.

iOS에서는 카메라와 사진 접근 권한 문구가 `ios/Runner/Info.plist`에 필요합니다. 현재 앱에는 카메라/사진 보관함 사용 설명이 포함되어 있습니다.

## 실행 준비

Flutter SDK와 Xcode, CocoaPods, Firebase 설정 파일이 필요합니다.

필수 설정 파일:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- FlutterFire: `lib/firebase_options.dart`

의존성 설치:

```bash
flutter pub get
```

iOS Pod 설치가 필요하면:

```bash
cd ios
pod install
cd ..
```

앱 실행:

```bash
flutter run
```

특정 iPhone으로 실행:

```bash
flutter devices
flutter run -d <device-id>
```

## iOS 주의사항

- 앱의 iOS 최소 버전은 `ios/Podfile` 기준 15.5입니다.
- Firebase 초기화는 Dart의 `Firebase.initializeApp(...)`에서 수행합니다. `AppDelegate.swift`에서 별도로 `FirebaseApp.configure()`를 호출하지 않습니다.
- Google ML Kit 관련 Pod가 Apple Silicon iOS 26+ 시뮬레이터 arm64 경고를 출력할 수 있습니다. 실제 iPhone 빌드/실행에서는 치명 오류가 아닐 수 있으므로, 우선 실기기에서 확인합니다.
- OCR 기능은 MLKit 네이티브 의존성이 있으므로 iOS Pod 변경 후에는 clean build가 필요할 수 있습니다.

## 학습 데이터 생성 및 모델 재학습

학습 데이터 생성:

```bash
python3 model/generate_memo_context_examples.py
```

모델 학습 및 TFLite 변환:

```bash
python3 model/train_memo_context_tflite.py
```

출력 파일:

- `assets/models/memo_context_classifier.tflite`
- `assets/models/memo_context_metadata.json`

학습 스크립트는 검증 정확도와 카테고리별 검증 정확도를 출력합니다. 모델을 교체한 뒤에는 반드시 앱에서 실제 메모 저장 흐름을 확인해야 합니다.

## 검증

정적 분석:

```bash
flutter analyze
```

테스트:

```bash
flutter test
```

iOS 디버그 빌드 확인:

```bash
flutter build ios --debug --no-codesign
```

현재 테스트는 `test/widget_test.dart`에서 메모 AI 서비스의 카테고리 추천과 날짜/요일 인식 케이스를 검증합니다.

## Firestore 데이터 개요

사용자 데이터는 `users/{uid}` 하위 컬렉션에 저장됩니다.

- `folders`: 폴더 이름, 색상, 메모 개수
- `memos`: 메모 내용, 폴더 ID, 생성일, AI 카테고리/확신도
- `events`: 일정 제목, 시작/종료 시간, 알림, 색상, 메모 출처

폴더 삭제 시 메모가 남아 있으면 `임시 폴더`로 이동시키는 흐름이 있습니다.

## 개발 메모

- 사용자 선택을 즉시 모델에 재학습하지 않습니다. 현재 모델 재학습은 `model/` 스크립트로 오프라인 수행합니다.
- 일정 감지와 자연어 날짜 파싱은 `memo_ai_service.dart`에 구현되어 있으며, 모델 분류와 별도 규칙 로직을 함께 사용합니다.
- 일정 저장 UI는 메모 저장 다이얼로그 안에서 시작/종료 시간과 알림을 사용자가 최종 확인하도록 되어 있습니다.
- 모델/학습 데이터 변경 시 `assets/models/memo_context_metadata.json`의 지표를 확인하고 테스트를 추가하는 것이 좋습니다.
