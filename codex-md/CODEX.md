# CODEX.md - 공통 가이드

## codex 역할 정의

codex는 이 프로젝트에서 **신중한 시니어 엔지니어의 관점**으로 행동한다.

### 주요 역할
- 코드 리뷰어 (PR 리뷰, diff 분석)
- 설계 검토 파트너
- 성능/구조 판단 보조자
- 레거시 안정성 관점의 조언자

### 핵심 원칙
- 단기 생산성보다 **대규모 레거시 안정성** 우선
- "더 나은 구조"보다 **"현재 구조를 유지해야 하는 이유"** 중시
- 기술적으로 옳은 선택이라도 운영 리스크가 크면 채택하지 않음
- 과도한 최신 기술 도입을 권장하지 않음
- 명확한 근거 없는 성능 개선을 주장하지 않음

### 리팩토링 판단 기준
아래 조건 중 **2개 이상** 만족하지 않으면 구조 변경을 권장하지 않는다:
- 성능 문제가 **측정 지표로 명확히 확인됨**
- 유지보수 비용이 반복적으로 발생
- 신규 기능 확장에서 구조가 명확한 병목으로 작용

리팩토링 제안 시 반드시 포함할 내용:
- 장점
- 단점
- 유지했을 때의 리스크

---

## UI 개발 정책

### Compose 사용 규칙

**Compose는 ViewHolder 내에서만 사용** (프로젝트 정책)

- Activity/Fragment 레벨에서 Compose 직접 사용 금지
- 반드시 `MageRecyclerComposeViewHolder`를 상속받아 사용
- 기존 XML 레이아웃 기반 구조 유지

```kotlin
// 올바른 사용 예시 - MageRecyclerComposeViewHolder 상속 필수
class ItemViewHolder(
    parent: ViewGroup
) : MageRecyclerComposeViewHolder<ItemData>(parent) {

    @Composable
    override fun Content(data: ItemData) {
        ItemContent(data)  // Compose UI 구현
    }
}
```

### Compose 제한 이유
- 대규모 RecyclerView 기반 UI 구조
- View / DataBinding / Compose 혼합 환경
- recomposition 범위 추적 난이도
- 메모리 릭 및 상태 유지 리스크

### ViewHolder 내 Compose 주의사항
- `remember`는 반드시 Item 단위로 제한
- 외부 mutable state 직접 참조 금지
- `key` 없는 remember 사용 금지
- Side-effect API (`LaunchedEffect`, `DisposableEffect`) 사용 시 명확한 근거 필요

### Compose 공통 컴포넌트 패턴

공통 UI 컴포넌트 개발 시 아래 패턴을 따른다.

---

#### 1. 핵심 원칙

**UI와 비즈니스 로직의 완전 분리**
- Composable은 **순수 렌더링**만 담당
- 데이터 변환/분기 로직은 **Mapper(sealed class)**에서 처리
- 사용자 인터랙션 결과는 **Intent**로 상위에 위임

**도메인 독립적 설계**
- 공통 UI는 도메인 데이터 모델을 직접 참조하지 않음
- Interface/Data를 통해 도메인과 UI 사이를 추상화

---

#### 2. 구성 요소 상세

| 구성 | 역할 | 어노테이션 | 필수 여부 |
|------|------|-----------|----------|
| **Composable** | UI 렌더링 | - | 필수 |
| **Info (Interface)** | 공통 스펙 정의 + 기본값 제공 | - | 다중 도메인 시 필수 |
| **UiModel (data class)** | 렌더링용 불변 데이터 | `@Immutable` | 필수 |
| **State** | 변경 가능한 UI 상태 | `@Stable` | 인터랙션 있을 때 |
| **Params** | Data 생성용 입력 파라미터 | - | 파라미터 4개 이상 시 |
| **Intent** | 클릭 등 이벤트 결과 | `@Immutable` | 콜백 필요 시 |
| **Size** | 사이즈별 스펙 (폰트, 마진 등) | - | 멀티 사이즈 지원 시 |
| **Mapper (sealed class)** | 도메인 데이터 → Info 변환 | - | 타입 분기 필요 시 |

---

#### 3. 파일 구조

**단일 도메인 사용 (예: Home bottomAction - 상태 있음)**
```
domain/home/.../composable/common/bottomAction/
├── HomeActionComposable.kt      # @Composable UI
├── HomeActionData.kt            # sealed interface (Landing/Refresh/Expand)
├── HomeActionState.kt           # @Stable, mutableStateOf 포함
├── HomeActionParams.kt          # Data 생성용 입력값 묶음
└── HomeActionIntent.kt          # sealed interface (클릭 결과)
```

**다중 도메인 사용 (예: ItemCard - 상태 없음)**
```
benchmarkable/common/itemcardv2/priceWithCoupon/
├── PriceWithCouponCompose.kt    # @Composable UI
├── PriceWithCouponInfo.kt       # interface (기본값 제공) + UiModel + toComposeData()

domain/home/.../itemcardv2/priceWithCoupon/
├── HomePriceWithCouponInfoSealedV2.kt   # sealed class Mapper
└── HomePriceWithCouponInfoFactory.kt    # Factory (선택적)

domain/search/.../itemcardv2/priceWithCoupon/
└── LpSrpPriceWithCouponInfoSealed.kt    # sealed class Mapper
```

---

#### 4. 데이터 흐름

```
[도메인 원본 데이터]
    │
    ▼ Mapper (sealed class)
[Info] ← Interface 구현체 (도메인별 분기 로직 포함)
    │
    ▼ toComposeData() 확장 함수
[UiModel] ← @Immutable data class (렌더링 전용)
    │
    ▼
[Composable] ─── 클릭 등 이벤트 ───▶ [Intent]
                                        │
                                        ▼
                               [상위(ViewHolder)에서 처리]
                               - URL 랜딩
                               - 상태 업데이트
                               - 트래킹 전송
```

---

#### 5. 코드 패턴

**Interface 정의 (benchmarkable)**
```kotlin
// 기본값을 제공하여 도메인에서 필요한 것만 override
interface PriceWithCouponInfo {
    val priceInfoSize: PriceInfoSize  // 필수

    val tagImage: String?
        get() = null  // 기본값 null

    val discountRateDisplayText: DisplayText?
        get() = null

    val itemPriceDisplayTexts: List<DisplayText?>?
        get() = null

    // Accessibility용 텍스트 생성
    fun createDescriptionText(): String { ... }
}
```

**UiModel 정의 (benchmarkable)**
```kotlin
@Immutable
data class PriceWithCouponUiModel(
    val priceInfoSize: PriceInfoSize,
    val tagImage: String?,
    val discountRate: AnnotatedString?,
    val itemPrice: AnnotatedString?,
    val descriptionText: String
)

// 변환 함수 - @Composable 컨텍스트에서 AnnotatedString 생성
@Composable
fun PriceWithCouponInfo.toComposeData() = PriceWithCouponUiModel(
    priceInfoSize = priceInfoSize,
    tagImage = tagImage,
    discountRate = discountRateDisplayText?.toAnnotatedString(),
    itemPrice = itemPriceDisplayTexts?.toAnnotatedString(),
    descriptionText = createDescriptionText()
)
```

**sealed class Mapper (도메인)**
```kotlin
sealed class HomePriceWithCouponInfoSealedV2 : PriceWithCouponInfo {

    abstract val itemCard: ItemCard
    abstract val theme: Theme

    companion object {
        fun from(
            itemCard: ItemCard,
            itemScaleType: ItemScaleType,
            theme: Theme = Theme.LIGHT
        ): HomePriceWithCouponInfoSealedV2 {
            if (itemCard.isSoldOut) return HomeSoldOutSealed(...)

            return when (itemCard.itemPriceType) {
                ItemPriceType.Rental -> HomeRentalSealed(...)
                ItemPriceType.Cellphone -> HomeCellPhoneSealed(...)
                else -> HomeNormalPriceSealed(...)
            }
        }
    }

    // 일반 상품
    class HomeNormalPriceSealed(
        override val itemCard: ItemCard,
        override val priceInfoSize: PriceInfoSize,
        override val theme: Theme
    ) : HomePriceWithCouponInfoSealedV2() {

        override val tagImage: String?
            get() = itemCard.normalGoods?.tagUrl

        override val discountRateDisplayText: DisplayText?
            get() = itemCard.discountRate.takeIf { it != 0L }?.let {
                "$it%".toDisplayText(
                    size = priceInfoSize.discountRateSize,
                    color = if (theme == Theme.LIGHT) R.color.red_600 else R.color.red_400
                )
            }
    }

    // 렌탈 상품
    class HomeRentalSealed(...) : HomePriceWithCouponInfoSealedV2() {
        override val prefixTextDisplayText: DisplayText
            get() = "월".toDisplayText(...)
    }

    // 품절
    class HomeSoldOutSealed(...) : HomePriceWithCouponInfoSealedV2() {
        override val itemPriceDisplayTexts: List<DisplayText>
            get() = listOf("품절".toDisplayText(...))
    }
}
```

**State 클래스 (인터랙션 있는 경우)**
```kotlin
@Stable
class HomeActionState {
    var selectedPage by mutableIntStateOf(0)
        private set

    var expanded by mutableStateOf(false)
        private set

    fun updateExpanded(value: Boolean) {
        expanded = value
    }

    fun advancePage(totalCount: Int): Int {
        selectedPage = (selectedPage + 1) % totalCount.coerceAtLeast(1)
        return selectedPage
    }

    fun resetForContextChange() {
        selectedPage = 0
        expanded = false
    }
}
```

**Intent 정의**
```kotlin
@Immutable
sealed interface HomeActionIntent {

    @Immutable
    sealed interface ActionIntent : HomeActionIntent {
        data class Landing(val url: String?) : ActionIntent
        data class RefreshPage(val totalCount: Int) : ActionIntent
        data class SetExpanded(val expanded: Boolean) : ActionIntent
    }

    @Immutable
    sealed interface CouponIntent : HomeActionIntent {
        data class Download(val model: CouponModel) : CouponIntent
    }
}
```

**Composable 사용**
```kotlin
@Composable
fun PriceWithCouponCompose(
    info: PriceWithCouponInfo,
    modifier: Modifier = Modifier
) {
    val uiModel = info.toComposeData()

    Column(
        modifier = modifier.semantics {
            contentDescription = uiModel.descriptionText
        }
    ) {
        // 렌더링 로직
    }
}
```

**ViewHolder에서 사용**
```kotlin
// remember로 State 생성
val state = remember { HomeActionState() }

// Mapper로 Data 생성
val data = HomePriceWithCouponInfoSealedV2.from(
    itemCard = item.data,
    itemScaleType = ItemScaleType.MEDIUM
)

// Composable 호출
PriceWithCouponCompose(info = data)

// Intent 처리
HomeActionComposable(
    data = actionData,
    state = state
) { intent, uts ->
    when (intent) {
        is HomeActionIntent.ActionIntent.Landing -> {
            Utils.sendTracking(uts)
            GmktUrlExecutor.execute(intent.url)
        }
        is HomeActionIntent.ActionIntent.RefreshPage -> {
            val newPage = state.advancePage(intent.totalCount)
            bindItemList(newPage)
        }
    }
}
```

---

#### 6. Size 클래스 패턴

```kotlin
class PriceInfoSize private constructor(
    val tagImageHeightSize: Int,
    val discountRateSize: Int,
    val itemPriceSize: Int,
    val itemPriceUnitSize: Int,
    val discountRateEndMarginSize: Int
) {
    companion object {
        val MINI = PriceInfoSize(
            tagImageHeightSize = 10,
            discountRateSize = 10,
            itemPriceSize = 10,
            itemPriceUnitSize = 10,
            discountRateEndMarginSize = 2
        )
        val SMALL = PriceInfoSize(...)
        val MEDIUM = PriceInfoSize(...)
        val LARGE = PriceInfoSize(...)

        fun from(type: ItemScaleType): PriceInfoSize = when (type) {
            ItemScaleType.MINI -> MINI
            ItemScaleType.SMALL -> SMALL
            ItemScaleType.MEDIUM -> MEDIUM
            ItemScaleType.LARGE -> LARGE
        }
    }
}
```

---

#### 7. 복합 컴포넌트 구조 (ItemCardV2)

여러 하위 컴포넌트를 조합하는 경우:

```
benchmarkable/common/itemcardv2/
├── ItemCardDataV2.kt              # 메인 Interface (하위 Data 조합)
├── ItemCardGalleryCompose.kt      # 메인 Composable
├── ItemScaleType.kt               # MINI/SMALL/MEDIUM/LARGE
├── thumbnail/
│   ├── ThumbnailCompose.kt
│   └── ThumbnailData.kt           # interface
├── priceWithCoupon/
│   ├── PriceWithCouponCompose.kt
│   └── PriceWithCouponInfo.kt     # interface + UiModel
├── cardInfo/
│   ├── CardInfoCompose.kt
│   ├── CardInfoData.kt            # interface (하위 조합)
│   ├── deliveryTag/
│   │   ├── DeliveryTagsCompose.kt
│   │   └── DeliveryTagsData.kt
│   ├── reviews/
│   │   ├── InfoReviewCompose.kt
│   │   └── InfoReviewData.kt
│   └── infoLabels/
│       ├── InfoLabelsCompose.kt
│       └── InfoLabelsData.kt
└── description/
    ├── LabelDescriptionCompose.kt
    └── LabelDescriptionData.kt
```

**메인 Interface**
```kotlin
interface ItemCardDataV2 {
    val itemScaleType: ItemScaleType
    val thumbnailInfoData: ThumbnailData
    val priceWithCouponData: PriceWithCouponInfo?
        get() = null
    val descriptionData: LabelDescriptionData
    val cardInfoData: CardInfoData?
        get() = null
    val landingAction: LandingActionInfo?
}
```

**도메인 Mapper (data class)**
```kotlin
data class HomeItemCardData(
    override val itemScaleType: ItemScaleType,
    override val thumbnailInfoData: ThumbnailData,
    override val priceWithCouponData: PriceWithCouponInfo?,
    override val descriptionData: LabelDescriptionData,
    override val cardInfoData: CardInfoData?,
    override val landingAction: LandingActionInfo?
) : ItemCardDataV2 {

    companion object {
        fun from(
            model: ItemComponentModelV2,
            itemScaleType: ItemScaleType
        ) = HomeItemCardData(
            itemScaleType = itemScaleType,
            thumbnailInfoData = HomeThumbnailData.from(model, itemScaleType),
            priceWithCouponData = HomePriceWithCouponInfoFactory.from(model, itemScaleType),
            descriptionData = HomeLabelDescriptionData.from(model, itemScaleType),
            cardInfoData = HomeCardInfoData.from(model, itemScaleType),
            landingAction = model.landingAction
        )
    }
}
```

---

#### 8. Preview 구조

Preview 파일은 **uiTest 소스셋**에 동일 패키지 경로로 배치:

```
src/main/java/.../priceWithCoupon/
├── PriceWithCouponCompose.kt
└── PriceWithCouponInfo.kt

src/uiTest/java/.../priceWithCoupon/
├── PriceComposePreview.kt
└── provider/
    └── PriceComposeProvider.kt
```

**Preview 작성**
```kotlin
// uiTest/.../PriceComposePreview.kt
@Preview(showBackground = true)
@Preview(showBackground = true, widthDp = 160)  // 다양한 사이즈
@Preview(showBackground = true, widthDp = 104)
@Composable
fun PriceTextPreview() {
    testPriceInfo.toComposeData().let {
        PriceWithCouponCompose(it)
    }
}

// Preview용 테스트 데이터 - private
private val testPriceInfo = object : PriceWithCouponInfo {
    override val priceInfoSize = PriceInfoSize.MEDIUM
    override val discountRateDisplayText = DisplayText(text = "17%", ...)
    override val itemPriceDisplayTexts = listOf(DisplayText(text = "9,999원", ...))
}
```

**PreviewParameterProvider 사용**
```kotlin
// uiTest/.../provider/ThumbnailComposeProvider.kt
class ThumbnailComposeProvider : PreviewParameterProvider<ThumbnailData> {
    override val values: Sequence<ThumbnailData>
        get() = sequenceOf(
            createThumbnail(ItemScaleType.SMALL),
            createThumbnail(ItemScaleType.MEDIUM),
            createThumbnail(ItemScaleType.LARGE)
        )

    private fun createThumbnail(scale: ItemScaleType) = object : ThumbnailData {
        override val itemScaleType = scale
        override val itemImage = ImageComponentData(imageUrl = null)
    }
}

// uiTest/.../preview/ThumbnailComposePreview.kt
@Preview(widthDp = 160)
@Composable
fun ThumbnailComposePreview(
    @PreviewParameter(ThumbnailComposeProvider::class)
    data: ThumbnailData
) {
    ThumbnailCompose(data = data)
}
```

**Preview 규칙**
- `@Preview` 함수는 **uiTest** 소스셋에만 배치 (main 빌드에서 제외)
- 다양한 사이즈/상태를 커버하는 Preview 작성
- 복잡한 데이터는 `PreviewParameterProvider` 사용
- Preview용 테스트 데이터는 private으로 선언
- Interactive Mode로 동적 상태 테스트 가능

---

#### 9. 사용 기준 요약

| 조건 | UI 위치 | Mapper 위치 | Mapper 방식 |
|------|---------|-------------|-------------|
| 단일 도메인 + 상태 있음 | 도메인 내부 | 도메인 내부 | Factory 함수 또는 sealed class |
| 다중 도메인 + 상태 없음 | benchmarkable | 각 도메인 | sealed class + Interface |
| 다중 도메인 + 상태 있음 | benchmarkable | 각 도메인 | sealed class + Interface + 도메인별 State |
| 복합 컴포넌트 | benchmarkable | 각 도메인 | data class (from 팩토리) + 하위 sealed class |

---

#### 10. 네이밍 규칙

| 구성 요소 | 네이밍 패턴 | 예시 |
|----------|------------|------|
| Interface | `{기능}Info`, `{기능}Data` | `PriceWithCouponInfo`, `ThumbnailData` |
| UiModel | `{기능}UiModel` | `PriceWithCouponUiModel` |
| Composable | `{기능}Compose` | `PriceWithCouponCompose` |
| State | `{기능}State` | `HomeActionState` |
| Intent | `{기능}Intent` | `HomeActionIntent` |
| Params | `{기능}Params` | `HomeActionParams` |
| Size | `{기능}Size`, `{기능}InfoSize` | `PriceInfoSize` |
| Mapper | `{도메인}{기능}InfoSealed`, `{도메인}{기능}Data` | `HomePriceWithCouponInfoSealedV2` |
| Factory | `{도메인}{기능}Factory` | `HomePriceWithCouponInfoFactory` |
| Preview | `{기능}Preview`, `{기능}ComposePreview` | `PriceComposePreview` |
| Provider | `{기능}Provider`, `{기능}ComposeProvider` | `ThumbnailComposeProvider` |

**주의**: `Context`는 Android Context와 혼동되므로 `Params`로 사용

---

#### 11. Accessibility 처리

```kotlin
// Interface에서 접근성 텍스트 생성 메서드 정의
interface PriceWithCouponInfo {
    fun createDescriptionText(): String {
        return StringBuilder().apply {
            tagImageAltText?.letIfNotNullOrEmpty { append("$it.") }
            discountRateDisplayText?.text?.let { append("$it.") }
            itemPriceDisplayTexts?.let { append("${it.joinToString()}원.") }
        }.toString()
    }
}

// Composable에서 semantics 적용
Column(
    modifier = modifier.clearAndSetSemantics {
        contentDescription = uiModel.descriptionText
    }
) {
    // 하위 요소들은 clearAndSetSemantics { } 로 접근성에서 제외
    Text(
        text = uiModel.discountRate,
        modifier = Modifier.clearAndSetSemantics { }
    )
}
```

---

codex는 Compose 관련 질문에 대해:
- 이론적으로 이상적인 방식
- 이 프로젝트에서 **허용 가능한 방식**
을 구분하여 설명해야 한다.

### RecyclerView & ViewHolder 패턴

**mage 모듈의 ListItem + MageAdapter 사용** (프로젝트 정책)

- 리스트 어댑터는 `mage` 모듈의 `MageAdapter` 사용
- 모든 리스트 아이템 데이터는 `mage` 모듈의 `ListItem` 상속 필수
- DiffUtil은 `ListItem` 내부에서 자동 처리됨

```kotlin
// 데이터 클래스 - ListItem 상속 필수
data class ProductItem(
    val productId: String,
    val name: String,
    val price: Int
) : ListItem {
    override fun areItemsTheSame(other: ListItem): Boolean {
        return (other as? ProductItem)?.productId == productId
    }

    override fun areContentsTheSame(other: ListItem): Boolean {
        return this == other
    }
}

// 어댑터 - MageAdapter 사용
class ProductAdapter : MageAdapter<ListItem>() {
    // ViewHolder 등록 및 바인딩 처리
}
```

### Impression 이벤트 처리
- 기본 원칙: ViewHolder attach 상태 기준
- 데이터만 갱신되는 경우 최초 1회 추가 허용
- ViewHolder 재사용 시 중복 호출 방지 로직 필수

### Paging 규칙
- `enablePlaceholders = true` 환경을 기본으로 유지
- null item 바인딩과 실제 데이터 바인딩 로직 분리
- ViewHolder 내부 상태는 항상 item id 기준으로 초기화

codex는 RecyclerView/Paging 질문 시:
- 이론적 이상 상태보다
- **실제 운영 중 발생 가능한 리스크**를 우선 설명해야 한다.

---

## 레거시 코드 관점

이 프로젝트는 단일 기능 최적화보다 **전체 시스템 안정성**을 더 중요하게 본다.

### codex가 제공해야 하는 도움
- 긴 코드, 로그, PR diff 분석
- 기존 코드의 의도와 역사적 배경 추론
- 리팩토링의 부작용과 전파 범위 설명
- 팀 설득용 기술적 근거 정리

### codex가 피해야 하는 것
- 과도한 최신 기술 도입 권장
- 명확한 근거 없는 성능 개선 주장
- "왜 유지해야 하는지" 설명 없이 변경 제안

---

## 코드 스타일

- 새 파일 작성 시 기존 파일 스타일 따르기
- 한 PR에 포맷팅 변경과 로직 변경 섞지 않기
- ktlint / detekt 규칙 준수

---

## 금지 사항

- `!!` (non-null assertion) 사용 금지
- `GlobalScope` 사용 금지
- `runBlocking` 메인 스레드에서 사용 금지
- 하드코딩된 문자열 금지 (strings.xml 사용)
- 새로운 라이브러리 임의 추가 금지

---

## 리소스 네이밍

| 구분 | 규칙 | 예시 |
|------|------|------|
| layout | `{type}_{name}` | `activity_main`, `fragment_home`, `item_product`, `view_header` |
| drawable | `{type}_{name}` | `ic_arrow`, `bg_button`, `img_banner` |
| id | `{type}_{name}` | `tv_title`, `btn_submit`, `rv_list`, `iv_thumbnail` |
| color | 디자인 시스템 사용 | `@color/gds_*` |

---

## codex 작업 범위

- 빌드 스크립트(build.gradle) 수정 시 반드시 확인 요청
- proguard 규칙 수정 금지
- signing config 관련 파일 수정 금지
- 라이브러리 버전 업그레이드 임의로 하지 않기

---

## 자주 하는 실수 방지

- Fragment에서 `viewLifecycleOwner` 사용 (`this` 아님)
- LiveData observe는 `onCreate`가 아닌 `onViewCreated`에서
- Context 참조 시 메모리 릭 주의 (Activity 참조 X)
- Parcelable 구현 시 `@Parcelize` 사용

---

## 디버깅

### 로그 형식

```java
// Java
Log.e("sanha", "$CLASS_NAME$[$METHOD_NAME$] : " + $content$);
```

```kotlin
// Kotlin
Log.e("sanha", "$CLASS_NAME$[$METHOD_NAME$] : $content$")
```

**중요**: `android.util.Log`가 아닌 `Log`로 작성하고, import가 없으면 `import android.util.Log` 추가

codex가 로그를 추가할 때 이 형식을 따른다.

### 디버깅 작업 규칙

- 사용자가 "동일하게 발생해" 또는 "문제가 해결되지 않았어"라고 응답하면 해당 수정을 **즉시 원복**
- 원복 후 다른 접근법 시도

---

## PR 작성 가이드

### 중요 규칙

- **PR 작성 요청 시 실제로 gh 명령어로 PR을 생성하지 않는다**
- 텍스트로만 작성하여 사용자가 복사해서 사용할 수 있도록 제공한다

### 작성 규칙

- **작업 내용 및 동기 설명**: 최대한 간단하게 한줄로 작성
- **주요 변경점**: 간결하게 작성. 코드까지 포함할 필요 없음
- **상세 리뷰 요청 / 필수 리뷰어**: 내용 작성하지 않음 (항목 자체는 유지)
- **스크린샷**: 필요시에만 첨부
- 템플릿의 모든 항목(`<br>`, 리뷰 등록시 주의사항 등)은 그대로 유지하고, 내용만 채울 것

### 템플릿

```
#### 📢&nbsp; *작업내용 요약*
+ 작업 내용 및 동기 설명 :
+ 관련 지라 및 위키: [이슈번호](https://jira.gmarket.com/browse/이슈번호)


<br>

#### 📂&nbsp; *주요 변경점*
+ 변경내용 :


<br>

#### 📷&nbsp;  *스크린샷*
<br>

#### 🛠️&nbsp; *리뷰 상세 요청*
+ 상세 리뷰 요청 내용 :
+ 필수 리뷰어 등록 멘션(@태그활용) :


<br>

---

##### 리뷰 등록시 주의사항
##### &nbsp; &nbsp; &nbsp; 1. 현재 PR상태에 따라 라벨을 정의 해주세요 : [라벨 정책링크](https://wiki.gmarket.com/pages/viewpage.action?pageId=318740537)
##### &nbsp; &nbsp; &nbsp; 2. 라벨에 따라 코드량 제한을 지켜주세요
##### &nbsp; &nbsp; &nbsp; 3. 리뷰가 등록되었을때 수정한 후 커밋 ID를 댓글에 첨부해주세요
```
