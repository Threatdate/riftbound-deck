# Riftbound Deck

Flutter와 SQLite를 사용해 만든 **Riftbound 카드 수집 및 덱 구성
앱**입니다. 카드 보유 수량을 관리하고, 덱을 구성하며, 부족한 카드를
확인할 수 있도록 제작했습니다.


## 주요 기능

-   **카드 검색 및 필터링**: 카드 이름/번호 검색, 시리즈·종류·속성·등급
    필터
-   **보유 카드 관리**: 카드별 보유 수량 증감 및 로컬 저장
-   **덱 생성 및 편집**: 덱 이름 설정, 카드 추가/삭제, 수량 조절
-   **덱 구성 규칙 확인**: 메인 덱, 레전드, 룬, 전장 구성과 카드별 제한
    확인
-   **부족 카드 확인**: 덱 필요 수량과 보유 수량을 비교해 부족한 카드
    표시
-   **덱 코드 가져오기/내보내기**: 덱 구성을 문자열 형태로 가져오고
    내보내기


## 기술 스택

-   **Flutter / Dart** --- UI 및 앱 기능
-   **SQLite / sqflite** --- 로컬 데이터 저장
-   **Git / GitHub** --- 버전 관리 및 소스 코드 공유

## 프로젝트 구조

``` text
lib/
├── main.dart
├── database/
│   ├── database_helper.dart
│   └── card_data/
│       └── origins_cards.dart
└── screens/
    ├── home_screen.dart
    ├── card_screen.dart
    ├── deck_screen.dart
    ├── deck_create_screen.dart
    ├── deck_detail_screen.dart
    └── shortage_card_screen.dart
```

## 실행 방법

Flutter SDK와 Android 개발 환경이 설치되어 있어야 합니다.

``` bash
git clone https://github.com/Threatdate/riftbound-deck.git
cd riftbound-deck
flutter pub get
flutter run
```

릴리스 APK 빌드:

``` bash
flutter build apk --release
```

빌드 결과는 일반적으로 다음 경로에 생성됩니다.

``` text
build/app/outputs/flutter-apk/app-release.apk
```

## 주요 구현 포인트

-   SQLite 기반으로 카드와 보유 수량을 로컬에 저장
-   카드 검색 및 여러 조건을 조합한 필터링
-   덱 카드 수량 변경과 덱 구성 제한을 함께 고려한 UI 로직
-   덱 코드 가져오기/내보내기 형식의 호환성 유지
-   카드 데이터 파일을 화면 코드와 분리해 시리즈별 데이터 확장에 대비

## 개발 과정에서 다룬 문제

-   앱을 다시 실행해도 보유 카드 수량이 유지되도록 데이터 저장 흐름을
    구성했습니다.
-   덱 코드 가져오기와 내보내기 형식을 맞췄습니다.
-   덱이 제한 수량에 도달했을 때 추가 조작이 올바르게 제한되도록 수량
    변경 흐름을 조정했습니다.
-   필터와 카드 목록의 화면 공간을 개선했습니다.

## 다음 개선 계획

-   [ ] 새 카드 시리즈 데이터 추가 및 데이터 검증
-   [ ] 프로젝트 구조와 덱 규칙 로직에 대한 테스트 추가
-   [ ] APK 설치 및 업데이트 안내 정리

## Repository

https://github.com/Threatdate/riftbound-deck

## 참고

이 프로젝트는 개인 학습 및 포트폴리오 목적으로 제작했습니다. Riftbound
및 관련 지식재산권은 해당 권리자에게 있습니다. 이 프로젝트는 공식 앱이
아닙니다.
