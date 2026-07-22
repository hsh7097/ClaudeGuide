# SRP MVI 개발 가이드

## 목적

Gmarket Android SRP 화면에서 Compose/ViewHolder 모듈을 추가하거나 검토할 때, 기존 `ContentViewModel`, `SrpViewModel`의 intent/receiver 패턴을 기준으로 책임을 나눈다.

이 문서는 개인 작업 흐름에서 Codex를 검증용으로 사용할 때 기준 문서로 사용한다.

## 핵심 모델

```text
ViewHolder / Composable
    -> Intent 생성
    -> sendIntent(intent)
    -> Receiver.reducer(intent)
    -> ViewModel side effect / state update
    -> LiveData, Flow, ListItem state, paging data 갱신
```

`receiver`는 Android `BroadcastReceiver`가 아니라, View에서 올라온 intent를 처리하는 reducer/action handler다.

기본 인터페이스:

- `MVIIntentReceiver`: intent를 받는 쪽. 보통 ViewModel 또는 모듈 전용 receiver.
- `MVIIntentReceiver.MVIIntent<T>`: View에서 발생한 이벤트 모델. `state`는 결과를 반영할 대상 모델이다.
- `MVIIntentSender`: ViewHolder/Composable 쪽에서 `sendIntent`를 호출하는 통로.
- `MviIntentAggregateReceiver`: 여러 하위 receiver로 intent를 라우팅하는 receiver.

### MVIIntentReceiver 동작 규칙

`MVIIntentSender.sendIntent(intent)`는 현재 객체의 `receiver?.reducer(intent)`만 호출한다. receiver가 `null`이면 조용히 무시된다.

`MVIIntentReceiver.MVIIntent<T>`의 `state`는 reducer가 결과를 반영할 대상이다. SRP에서 `T`는 보통 `ListItem` 또는 모듈 ViewData다. 이 `state`는 새 immutable state 생성을 강제하는 값이 아니라, 기존 list item state를 유지하면서 액션 결과를 반영하기 위한 참조로 쓰이는 경우가 있다.

`MviIntentAggregateReceiver` 라우팅은 아래 순서다.

```text
reducer(intent)
    -> intent가 SubIntent면 subReceivers에서 먼저 매칭
    -> 매칭된 receiver가 있으면 해당 receiver.reducer(intent)
    -> 매칭되지 않았거나 SubIntent가 아니면 reduceForAggregateIntent(intent)
```

주의할 점:

- `subReceivers` 매칭은 `clazz.isAssignableFrom(intent::class.java)`이고 첫 번째 매칭만 사용한다. 상속/인터페이스가 겹치면 더 구체적인 타입을 우선 등록해야 한다.
- `sendIntentToSubReceiver()`는 `SubIntent` 라우팅만 시도하고 `reduceForAggregateIntent` fallback을 호출하지 않는다.
- SRP 개별 모듈 액션은 굳이 `SubIntent`로 만들지 않아도 된다. Fragment에서 모듈 receiver를 직접 주입하면 일반 `MVIIntent`로 충분하다.
- `ATrackingIntent`, `ATSIntent`처럼 공통 receiver가 필요한 intent는 `SubIntent`와 `subReceivers` 라우팅이 적합하다.

`TrackingComposeViewHolder`를 사용할 때는 두 경로를 구분한다.

- 생성자로 받은 `intentSender`는 ATracking/ATS helper의 tracking sender로 계속 사용된다.
- ViewHolder의 `sendIntent()`는 `receiver` 프로퍼티를 사용한다.
- 따라서 모듈 액션 receiver를 따로 주입하려면 subclass에서 `override val receiver`를 모듈 receiver로 넘긴다. 이때 tracking은 생성자 `aTrackingIntentSender`를 통해 기존대로 흐른다.

예시 흐름:

```text
SimpleContentListBannerViewHolder(
    aTrackingIntentSender = fragment tracking sender,
    receiver = viewModel.simpleContentListBannerReceiver
)

sendIntent(ClickLanding(...))
    -> simpleContentListBannerReceiver.reducer(...)

sendAExposureTracking / ATS helper
    -> aTrackingIntentSender.receiver
```

## 이 앱에서의 MVI 해석

이 프로젝트의 SRP 구조는 일반적인 "immutable 단일 UiState + 순수 reducer" MVI와 다르다.

일반 MVI는 보통 `oldState + intent -> newState`를 만들고 `StateFlow`/`LiveData`로 새 상태를 방출한다. 반면 SRP는 기존 RecyclerView/Mage list 구조 위에서 `intent/receiver`로 액션과 side effect 책임을 분리하는 하이브리드 구조다.

따라서 SRP MVI 검토 기준은 아래에 둔다.

- ViewHolder/Composable은 UI 렌더링, local visual state, intent 생성까지만 담당한다.
- Receiver/ViewModel은 landing, tracking, cart, login, API, list item state 변경을 담당한다.
- UI 변경이 기존 ListItem 내부 상태 변경으로 충분한 경우 receiver에서 `intent.state.data`에 접근해 변경할 수 있다.
- 단, `state.data`를 변경해도 Compose가 관찰하지 못하거나 RecyclerView 갱신 경로가 없으면 UI가 다시 그려진다고 보장하지 않는다. 이 경우 observable state, item 갱신, list 재생성 중 기존 패턴에 맞는 갱신 경로가 필요하다.
- 서버 응답, paging data, module 구성 자체가 바뀌는 변경은 단순 `state.data` mutation보다 ViewModel의 list/state 갱신 경로를 우선 검토한다.

## ContentViewModel 패턴

`ContentViewModel`은 `MviIntentAggregateReceiver`를 구현한다.

주요 특징:

- Fragment에서 `MVIIntentSender.receiver = viewModel`로 연결한다.
- `subReceivers`에 하위 intent 타입과 receiver를 등록한다.
- `HomeRecommendedBaseIntent`, `ATrackingIntent`, `ATSIntent`처럼 공통/모듈 intent를 타입 기반으로 라우팅한다.
- 하위 receiver가 필요하면 다시 `ContentViewModelIntent`를 만들어 상위 ViewModel 작업을 요청한다.

흐름 예:

```text
HomeRecommendedBaseComposeViewHolder
    -> HomeRecommendedBaseIntent.ClickTab
    -> ContentViewModel.reducer
    -> HomeRecommendedReceiver.reducer
    -> 필요 시 ContentViewModelIntent.UpdateComponentItem
    -> ContentViewModel.reduceForAggregateIntent
    -> API 호출 / 쿠폰 갱신 / 모듈 state update
```

적용하기 좋은 경우:

- 여러 모듈이 동일 sender로 ViewModel에 intent를 던진다.
- tracking, coupon, API refresh처럼 공통 receiver 라우팅이 필요하다.
- 하위 receiver가 자체 state를 들고 있고, 일부 작업만 ViewModel에 위임한다.

## SrpViewModel 패턴

`SrpViewModel`도 `MviIntentAggregateReceiver`를 구현하지만, SRP 모듈 액션은 모듈별 receiver를 직접 ViewModel 안에 두는 패턴이 많다.

주요 특징:

- `subReceivers`는 주로 `ATrackingIntent`, `ATSIntent` 라우팅에 사용한다.
- 모듈별 액션은 `topRelatedKeywordReceiver`, `groupingItemReceiver`, `srpDaPremiumBannerReceiver`, `cartRecommenderSubReceiver`처럼 ViewModel 내부 receiver로 분리한다.
- `SearchResultFragment`에서 해당 receiver를 ViewHolder 생성자에 직접 주입한다.

흐름 예:

```text
TopRelatedKeywordComposeViewHolder
    -> TopRelatedKeywordIntent.ClickItem
    -> viewModel.topRelatedKeywordReceiver.reducer
    -> sendUTSClickLpSrp
    -> changeEvent(LpSrpEventData.clickUxElement)
```

```text
GroupingItemComposeViewHolder
    -> SrpGroupingIntent.ClickCart
    -> viewModel.groupingItemReceiver.reducer
    -> UTS / Firebase / cart API / login or option flow
```

적용하기 좋은 경우:

- SRP 특정 모듈의 클릭, 랜딩, 장바구니, 광고 로그 처리가 필요하다.
- ViewHolder에는 UI와 intent 생성만 두고, side effect는 `SrpViewModel`에서 처리한다.
- 모듈별 receiver를 명시적으로 주입해 연결 지점을 드러내고 싶다.
- `reduceForAggregateIntent`에 개별 모듈 액션을 계속 추가하기보다 `simpleContentListBannerReceiver` 같은 모듈 전용 receiver를 우선 둔다.

## 새 SRP 모듈 추가 절차

### 1. 데이터 진입점 확인

API 응답의 `modelName`, `designName`, row/module 구조를 확인한다.

검토 지점:

- `SrpResultData.kt`: `modelName`과 실제 ViewModelData class 매핑
- `SrpResult.kt`: raw response model
- `SearchListManager.kt`: response model을 `ListItem`으로 변환
- `SrpListItem.kt`: RecyclerView adapter에 들어갈 `ListItem`

### 2. ListItem 정의

모듈 단위로 RecyclerView에 들어갈 data class를 만든다.

선택 기준:

- tracking/exposure가 있으면 `TrackingStateListItem` 또는 기존 tracking ListItem 계열을 따른다.
- 일반 UI 모듈이면 `SearchListItem`과 기존 동등성 비교 패턴을 따른다.
- 하단 divider/margin 정책이 있으면 `needDivider`, `needBottomMarginItem`을 명시한다.

### 3. SearchListManager 매핑

`SearchListManager.makeListData`에서 `modelName`/`designName`에 따라 새 ListItem으로 변환한다.

주의:

- 기존 `addModuleItems`를 쓰는 모듈은 region margin/divider 정책까지 같이 따라간다.
- 단순 item 추가와 module item 추가의 차이를 기존 주변 코드 기준으로 맞춘다.
- API model이 확정되기 전에는 임시 UI 코드와 실제 mapper를 분리해 둔다.

### 4. ViewData/Mapper 분리

raw response model을 Composable이 직접 해석하지 않도록 ViewData 또는 mapper를 둔다.

권장:

- Composable에는 화면에 필요한 값만 넘긴다.
- URL, tracking, API body, item number 등 side effect에 필요한 값은 intent state/data에 포함될 수 있게 보존한다.
- 도메인 규칙 계산은 mapper 또는 ViewModel 쪽에서 값으로 확정한다.

### 5. ViewHolder 작성

선택 기준:

- ATS/ATracking이 필요한 Compose 모듈: `TrackingComposeViewHolder`
- 단순 Compose 모듈: `MageRecyclerComposeViewHolder`
- 기존 XML ViewHolder: `TrackingViewHolder` 또는 기존 SRP base ViewHolder

ViewHolder 책임:

- Composable에 view data와 callback 연결
- 사용자 액션을 intent로 포장
- `itemView`, `index`, `state`, `tracking data`, `FragmentManager` 등 reducer에 필요한 최소 정보 전달
- 직접 API 호출, navigation, cart 처리, repository 접근 금지

### 6. Intent 정의

모듈 내부 또는 별도 파일에 sealed interface로 정의한다.

예시:

```kotlin
sealed interface SelectiIntent {
    data class ClickMore(
        override val state: SelectiListItem,
        val view: View,
        val link: String?
    ) : SelectiIntent, MVIIntentReceiver.MVIIntent<SelectiListItem>

    data class ClickItem(
        override val state: SelectiListItem,
        val view: View,
        val item: SelectiItemViewData
    ) : SelectiIntent, MVIIntentReceiver.MVIIntent<SelectiListItem>
}
```

원칙:

- intent 이름은 UI 이벤트가 아니라 사용자의 의도를 표현한다.
- `OnClick`보다 `ClickMore`, `ClickItem`, `ClickCart`, `SendAtsImpression`처럼 구체화한다.
- ViewModel 처리를 위해 필요한 값만 싣는다.
- nullable 값은 reducer에서 안전하게 처리하고 `!!`를 쓰지 않는다.

### 7. Receiver 위치 결정

SRP 모듈은 기본적으로 `SrpViewModel` 내부에 모듈별 receiver를 둔다.

```kotlin
val selectiReceiver: MVIIntentReceiver by lazy {
    object : MVIIntentReceiver {
        override fun reducer(intent: MVIIntentReceiver.MVIIntent<*>) {
            when (intent) {
                is SelectiIntent.ClickMore -> {
                    sendUTSClickLpSrp(intent.view, intent.state.data.moreUts)
                    changeEvent(LpSrpEventData.openWebView(intent.link))
                }
            }
        }
    }
}
```

`SubIntent`/aggregate를 우선 고려할 때:

- 공통 tracking intent
- 여러 모듈이 공유하는 receiver
- Content 영역처럼 ViewModel 전체 sender를 통해 라우팅하는 구조

SRP 개별 모듈은 명시적 receiver 주입이 현재 코드베이스와 더 잘 맞는다.

별도 receiver 타입을 만들지 판단할 때:

- 액션이 `ClickLanding` 하나 정도인 단순 모듈은 `val moduleReceiver: MVIIntentReceiver by lazy { object : MVIIntentReceiver { ... } }`로 충분하다.
- `ClickItem`, `ClickCart`, `SendAtsImpression`, API 갱신처럼 액션이 늘어나거나 테스트/재사용/타입 명시가 필요하면 `ModuleReceiver : MVIIntentReceiver` 인터페이스 또는 별도 receiver 클래스로 분리한다.
- `CartRecommenderSubReceiver`처럼 receiver 타입을 한 번 더 감싸는 구조는 모듈 책임이 커졌을 때 적용하고, 단순 랜딩/UTS 처리만 있는 단계에서는 과한 추상화로 본다.

### 8. Fragment adapter 연결

`SearchResultFragment.createAdapter`의 `viewHolderFactory`에 ViewHolder를 등록한다.

```kotlin
map {
    SelectiComposeViewHolder(
        parent = it,
        viewLifecycleOwner = viewLifecycleOwner,
        aTrackingIntentSender = aTrackingIntentSender,
        receiver = viewModel.selectiReceiver
    )
}
```

tracking만 필요한 child ViewHolder는 `aTrackingIntentSender`를 그대로 넘기고, 모듈 액션이 있으면 별도 receiver를 주입한다.

## 책임 분리 기준

### ViewHolder / Composable

허용:

- UI 렌더링
- local visual state
- callback에서 intent 생성
- Compose state, scroll state, animation state
- 노출 시점에 tracking intent 발행

금지:

- repository/API 호출
- `changeEvent` 직접 호출
- landing/navigation 직접 실행
- cart, login, dialog business flow 직접 처리
- ViewModel 내부 상태 직접 변경

### Intent

허용:

- 사용자 액션의 의미 표현
- reducer가 처리할 최소 데이터 전달
- `state`, `view`, `index`, `link`, tracking data 포함

금지:

- 자체 상태 변경
- API 호출
- UI rendering 정보 과다 보관

### Receiver / ViewModel

허용:

- intent type 분기
- UTS/ATS/ATracking 전송
- navigation event 발행
- repository/API 호출
- LiveData/Flow/ListItem state 갱신
- cart/login/dialog side effect

주의:

- reducer가 너무 커지면 receiver 클래스로 분리한다.
- SRP 개별 모듈 액션을 `reduceForAggregateIntent` fallback에 넣으면 연결 지점이 흐려질 수 있다. 단순/개별 모듈은 ViewModel 내부 모듈 receiver + Fragment 직접 주입을 우선한다.
- `intent.state.data` 변경은 이 앱에서 허용되는 패턴이지만, 변경 대상이 Compose recomposition 또는 RecyclerView item 갱신으로 이어지는지 같이 확인한다.
- UI에만 필요한 계산은 Composable/mapper로 내려보낸다.
- 동일 tracking이 ViewHolder와 receiver에서 중복 전송되지 않는지 확인한다.

## Selecti 적용 메모

현재 Selecti는 UI Composable만 있는 단계다.

API/액션 연결 시 예상 구조:

```text
Selecti raw API model
    -> SelectiViewData / mapper
    -> SelectiListItem
    -> SearchListManager mapping
    -> SelectiComposeViewHolder
    -> SelectiIntent
    -> SrpViewModel.selectiReceiver
    -> SearchResultFragment map 등록
```

예상 intent:

- `ClickMore`: 더보기 버튼 클릭, 랜딩/검색 결과 이동/UTS 처리
- `ClickItem`: 상품 클릭, VIP 이동/UTS/ATS 처리
- `ClickCart`: 장바구니가 생기면 cart flow 처리
- `SendAtsImpression`: 광고 모듈로 내려오면 ATS viewable impression 처리
- `SendAExposure`: AUT exposure가 별도 요구되면 tracking intent 또는 receiver 처리

UI만 개발 중일 때는 Composable 단독도 괜찮다. 다만 API 연결 시점에는 hardcoded mock data를 ViewData/mapper로 이동해야 한다.

## 리뷰 체크리스트

### 구조

- ViewHolder가 `sendIntent`만 하고 side effect를 직접 실행하지 않는가?
- receiver가 ViewModel 또는 모듈 전용 receiver에 명확히 연결되어 있는가?
- Fragment adapter에 올바른 receiver/sender가 주입되었는가?
- SRP 모듈인데 불필요하게 aggregate `SubIntent`로 복잡하게 만들지 않았는가?

### 데이터

- `SrpResultData.kt` model 매핑이 필요한 경우 추가되었는가?
- `SearchListManager`에서 `modelName`/`designName` 분기가 정확한가?
- `ListItem`의 `isItemsSame`, `isContentsSame`, margin/divider 정책이 기존 패턴과 맞는가?
- API 전 임시 mock/hardcoded 값이 production path에 남지 않았는가?

### 액션

- intent 이름이 사용자 의도를 표현하는가?
- click, more, cart, item, impression이 서로 분리되어 있는가?
- reducer에서 nullable 값을 안전하게 처리하는가?
- landing, cart, dialog, API 호출은 ViewModel/receiver에서 처리하는가?

### Tracking

- UTS click은 클릭 액션마다 정확히 한 번 전송되는가?
- ATS impression/click이 중복 전송되지 않는가?
- ATracking exposure/click이 `TrackingComposeViewHolder` 또는 explicit intent로 일관되게 처리되는가?
- `itemView`에 page id가 필요한 경우 `sendUTSClickLpSrp` 경로를 쓰는가?

### Compose/UI

- ViewData가 Composable에 필요한 값만 제공하는가?
- scroll state, selected tab 같은 UI state가 recomposition에 안전한가?
- `remember` key가 데이터 변경 조건을 반영하는가?
- receiver에서 `state.data`를 바꾸는 경우 UI 갱신 경로가 실제로 존재하는가?
- string resource, color/token, spacing이 기존 GDS/SRP 패턴을 따르는가?

### 검증

- 변경 후 최소 `./gradlew :GmarketMobile:compileProdDebugKotlin`을 실행한다.
- UI 변경은 Preview, screenshot, 또는 실제 화면에서 spacing/scroll/click area를 확인한다.
- action 연결 후에는 클릭, 더보기, 상품 클릭, 노출 tracking 로그를 각각 분리해서 확인한다.

## 판단 문장

검토할 때 아래 질문에 답한다.

- 이 코드는 UI를 그리는 책임과 side effect 책임이 분리되어 있는가?
- intent가 "무슨 일이 일어났는지"를 충분히 표현하는가?
- receiver가 "그 일을 어떻게 처리할지"를 기존 SRP 방식대로 처리하는가?
- 일반 MVI식 새 immutable state 방출이 아니라 SRP식 ListItem/state mutation 구조를 쓰는 이유가 기존 코드 패턴과 맞는가?
- API가 붙었을 때 mock/UI-only 코드가 자연스럽게 제거될 구조인가?
- tracking이 빠지거나 중복될 가능성이 있는가?
