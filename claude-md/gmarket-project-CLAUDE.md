# CLAUDE.md - Gmarket Android Project

> 공통 가이드는 `/Users/sanha/CLAUDE.md` 참조

## 프로젝트 개요

Gmarket은 eBay Korea에서 운영하는 대규모 이커머스 안드로이드 애플리케이션입니다. 12개의 모듈로 구성된 멀티모듈 프로젝트이며, MVVM + Clean Architecture 패턴을 사용합니다.

## 기술 스택

| 구분 | 기술 |
|------|------|
| **언어** | Kotlin 1.9.24, Java 17 |
| **SDK** | compileSdk 35, minSdk 23, targetSdk 35 |
| **UI** | XML/DataBinding + Compose (ViewHolder 내 제한적 사용) |
| **DI** | Hilt 2.47 |
| **비동기** | Coroutines 1.8.1, LiveData |
| **네트워크** | Retrofit 2.9.0, OkHttp 3.12.3 |
| **DB** | Room 2.6.1 |
| **이미지** | Glide 4.16.0, Coil 3.0.0 |
| **애니메이션** | Lottie 6.6.7 |
| **빌드** | Gradle Kotlin DSL, Version Catalog |

## 모듈 구조

```
Gmarket/
├── GmarketMobile/          # 메인 앱 모듈 (비즈니스 로직)
├── mage/                   # 코어 프레임워크/아키텍처 라이브러리
├── mageUi/                 # UI 컴포넌트 라이브러리 (mage 기반)
├── gds-android/            # 디자인 시스템 컴포넌트
├── montelena/              # 애널리틱스/트래킹 라이브러리
├── picturePicker/          # 이미지 선택 라이브러리
├── mage-annotation/        # 커스텀 어노테이션
├── mage-annotation-processing/  # 어노테이션 프로세서
├── baselineprofile/        # 스타트업 최적화용 베이스라인 프로필
├── benchmarkable/          # 벤치마크 테스트 모듈
├── designqa/               # 디자인 QA 모듈
└── lint-checks/            # 커스텀 린트 규칙
```

## 패키지 구조 (GmarketMobile)

```
com.ebay.kr.gmarket/
├── api/                # API 응답 래퍼 (ApiResult, BambooOptions, PdsApiOptions)
├── apps/               # Application 클래스 (GmarketApplication)
├── auth/               # 인증 (api/, data/, repository/)
├── base/               # 베이스 클래스 (activity/, ui/, webview/)
├── common/             # 공통 유틸리티 (BindingAdapters, CookieManager, preferences/)
├── dao/                # Room 데이터베이스 (GMKTRoomDatabase)
├── fcm/                # Firebase Cloud Messaging
├── launcher/           # 앱 런처/숏컷
├── lupin/              # 팝콘 알림 기능
├── main/               # 홈 화면 (data/, manager/, repository/, viewmodels/)
├── premium_review/     # 프리미엄 리뷰 (data/, repository/, ui/)
├── recentitem/         # 최근 본 상품
└── settings/           # 설정 화면 (data/, repository/, ui/)

com.ebay.kr/
├── di/                 # 의존성 주입 (AppModule.kt)
├── gmarketapi/         # API 레이어
├── gmarketui/          # UI 컴포넌트
├── expressshop/        # 익스프레스샵 기능
├── homeshopping/       # 홈쇼핑 기능
├── smiledelivery/      # 스마일배송 기능
├── tracking/           # 트래킹/애널리틱스
└── vip/                # VIP 기능 (Anna VIP)
```

## 아키텍처 패턴

### MVVM + Repository Pattern

```
View (Activity/Fragment/Compose)
    ↓
 ViewModel (@HiltViewModel)
    ↓
Repository
    ↓
DataSource (Remote API / Local DB)
```

### 주요 컴포넌트

- **ViewModel**: `@HiltViewModel`로 주입, `GmarketMainViewModel` 등
- **Repository**: `GmarketMainRepository`, `AuthRepository` 등
- **Service**: Retrofit 기반 API 서비스 (`StarGateDataService`, `PdsDataService` 등)
- **Database**: Room (`GMKTRoomDatabase`, 현재 버전 7)

## 주요 진입점

| 클래스 | 역할 |
|--------|------|
| `GmarketApplication.kt` | 앱 초기화, Hilt @HiltAndroidApp |
| `eBayKoreaGmarketActivity.kt` | 메인 딥링크 처리 Activity (1,154줄) |
| `GmarketActivity.kt` | 앱 게이트/라우팅 Activity |
| `GmarketMainViewModel.kt` | 홈 화면 상태 관리 |

## API 서비스 구조

```kotlin
// AppModule.kt에서 제공하는 주요 서비스
StarGateDataService       // 상품/홈 데이터 (메인 API)
StarGateFluxDataService   // Flux 데이터
PdsDataService           // 상품 상세
SearchDataService        // 검색
CategoryDataService      // 카테고리
CartApiService          // 장바구니
OptionApiService        // 상품 옵션
UploadImageService      // 이미지 업로드 (Bamboo)
```

### API Response 래핑

```kotlin
ApiResult<T>           // 제네릭 응답 래퍼
StarGateApiResult<T>   // StarGate API 전용
PdsApiResult<T>        // PDS API 전용
```

---

## 빌드 설정

### Build Types
- `debug` - 개발 빌드
- `debugFinal` - 난독화된 디버그 빌드 (테스트용)
- `release` - 프로덕션 빌드 (ProGuard 적용)
- `benchmark` - 벤치마크 테스트용

### Product Flavors
- `uiTest` - UI 테스트용
- `prod` - 프로덕션 (활성 플레이버)

### 주요 빌드 명령어

```bash
# 디버그 빌드
./gradlew :GmarketMobile:assembleProdDebug

# 릴리즈 빌드
./gradlew :GmarketMobile:assembleProdRelease

# 단위 테스트
./gradlew :GmarketMobile:testProdDebugUnitTest

# 린트 체크
./gradlew :GmarketMobile:lintProdDebug
```

## 트래킹 시스템 (4계층)

1. **Montelena** - 내부 애널리틱스 프레임워크
2. **Firebase Analytics** - Google 애널리틱스
3. **ATrack** - ATS 기반 트래킹
4. **PDS Tracker** - 상품 데이터 서비스 트래킹

## 코딩 컨벤션

### 파일 네이밍
- Activity: `*Activity.kt`
- Fragment: `*Fragment.kt`
- ViewModel: `*ViewModel.kt`
- Repository: `*Repository.kt`
- Service: `*Service.kt`
- UseCase: `*UseCase.kt`

### 패키지 네이밍
- 기능 기반: `main/`, `settings/`, `premium_review/`
- 레이어 기반: `data/`, `repository/`, `ui/`, `viewmodels/`

### Coroutine Dispatcher
```kotlin
// AppDispatchers 사용
appDispatchers.io      // IO 작업
appDispatchers.default // CPU 작업
appDispatchers.main    // UI 작업
```

## 주요 파일 위치

| 파일 | 경로 |
|------|------|
| DI 모듈 | `com/ebay/kr/di/AppModule.kt` |
| Application | `com/ebay/kr/gmarket/apps/GmarketApplication.kt` |
| Base Activity | `com/ebay/kr/gmarket/base/activity/GMKTBaseActivity.kt` |
| 메인 ViewModel | `com/ebay/kr/gmarket/main/viewmodels/GmarketMainViewModel.kt` |
| Room DB | `com/ebay/kr/gmarket/dao/GMKTRoomDatabase.kt` |
| 버전 카탈로그 | `gradle/libs.versions.toml` |
| ProGuard 설정 | `GmarketMobile/proguard-project.txt` |

## mage 모듈 (코어 프레임워크)

```
com.ebay.kr.mage/
├── api/          # Retrofit 빌더, HTTP 클라이언트 설정
├── arch/         # 아키텍처 패턴 (ViewModel, UseCase, Event)
├── base/         # Base Activity/Fragment
├── compose/      # Jetpack Compose 지원, MVI 패턴
├── concurrent/   # Coroutine Dispatcher (AppDispatchers)
├── core/tracker/ # 애널리틱스 인프라
├── di/           # Dagger/Hilt 유틸리티
├── common/       # 공통 확장 함수
└── webkit/       # WebView 관리
```

## 딥링크 처리

- **Scheme**: `gmarket://`
- **Dynamic Links**: Firebase Dynamic Links
- **Airbridge**: 딥링크 어트리뷰션 트래킹
- **URL Executor**: `GmktUrlExecutorFactory`로 URL 라우팅

## 테스트

```bash
# 단위 테스트
./gradlew test

# UI 테스트 (연결된 기기 필요)
./gradlew connectedAndroidTest

# 특정 테스트 실행
./gradlew :GmarketMobile:testProdDebugUnitTest --tests "*.ClassName"
```

### 테스트 라이브러리
- JUnit 4, Mockito, MockK
- Espresso, Barista (UI 테스트)
- Robolectric (로컬 Android 테스트)
- Hilt Testing

## 디자인 시스템

- GDS 가이드: https://gds.gmarket.co.kr/
- 구현 모듈: `gds-android/`

## 주의사항

1. **멀티모듈 의존성**: `GmarketMobile`은 `mage`, `gds-android`, `mageUi` 등에 의존
2. **Flavor 분리**: `src/gmarket/`과 `src/auction/`으로 플레이버별 코드 분리
3. **Room 마이그레이션**: DB 스키마 변경 시 마이그레이션 필수 (현재 v7)
4. **ProGuard**: 릴리즈 빌드 시 난독화 규칙 확인 필요
5. **SDK 라이브러리**: Montelena, mage 등은 내부 라이브러리로 외부 문서 없음

---

## 환경 변수 (CI)

```
TASK_NO      # 피처 브랜치 제어 (기본값: "6")
SERVER_ENV   # API 환경 선택 (기본값: "prod")
GIT_BRANCH   # Git 브랜치 정보
GIT_USER     # Git 사용자 정보
```
