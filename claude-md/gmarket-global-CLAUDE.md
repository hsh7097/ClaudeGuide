# CLAUDE.md - 공통 가이드

---

## 가이드 트리거 규칙

아래 키워드가 포함된 요청이 오면 해당 가이드 파일을 읽고 참조하여 응답한다.

| 트리거 키워드 | 유형 | 경로 | 설명 |
|--------------|------|------|------|
| `bi`, `BI`, `BI 작성`, `기술 공유 문서` | 스킬 `/bi` | `~/.claude/skills/bi-writing/SKILL.md` | BI(Bi-Weekly) 기술 공유 문서 작성 |
| `공통화`, `UI 공통화`, `도메인 공통화`, `Contract`, `Factory 패턴` | 스킬 `/공통화` | 프로젝트 `.claude/skills/ui-commonization/SKILL.md` | UI-도메인 공통화 작업 가이드 |
| `커밋`, `commit`, `푸시`, `push` | 스킬 `/커밋` | 프로젝트 `.claude/skills/safe-commit/SKILL.md` | 셀프 리뷰 후 안전 커밋 (브랜치 보호 포함) |
| `평가`, `연말평가`, `본인평가`, `성과 정리` | 가이드 | `~/.claude/guides/yearly-review.md` | 연말평가 본인평가 작성 |

**사용 방법**:
- **스킬**: Claude가 description 기반으로 자동 인식하여 실행. `/스킬명`으로도 직접 호출 가능.
- **가이드**: 트리거 키워드 감지 시 해당 파일을 Read 도구로 읽은 후 가이드에 따라 응답.

### 가이드/스킬 작업 시 필수 절차

가이드나 스킬 관련 작업(수정, 생성, 조회)을 할 때는 반드시:

1. **작업 전**: ClaudeGuide 저장소를 최신 상태로 갱신
   ```bash
   cd C:\Users\hsh70\AndroidStudioProjects\ClaudeGuide && git pull
   ```

2. **작업 후**: 가이드/스킬 파일이 변경되었으면 자동으로 커밋 & push
   ```bash
   cd C:\Users\hsh70\AndroidStudioProjects\ClaudeGuide && git add -A && git commit -m "가이드 업데이트: [변경 요약]" && git push
   ```

> 심볼릭 링크로 연결된 `~/.claude/guides/` 파일을 수정하면 ClaudeGuide 저장소의 원본이 변경된다. 반드시 커밋 & push 한다.

---

## 코딩 행동 원칙 (Karpathy Guidelines)

> LLM이 코드 작성/수정/리팩토링 시 흔히 하는 실수를 줄이기 위한 원칙. 속도보다 신중함에 편향. 사소한 작업에는 판단에 따라 적용.

### 1. Think Before Coding
- 가정을 명시적으로 말하라. 불확실하면 물어봐라.
- 여러 해석이 가능하면 제시하라 - 조용히 하나를 선택하지 마라.
- 더 단순한 접근법이 있으면 말하라. 필요할 때 반론을 제기하라.
- 뭔가 불분명하면 멈춰라. 무엇이 혼란스러운지 말하고 물어봐라.

### 2. Simplicity First
- 요청받지 않은 기능 추가 금지.
- 한 번만 쓰이는 코드에 추상화 금지.
- 요청하지 않은 "유연성"이나 "설정 가능성" 금지.
- 불가능한 시나리오에 대한 에러 핸들링 금지.
- 200줄로 썼는데 50줄이면 될 경우, 다시 써라.

### 3. Surgical Changes
- 인접 코드, 주석, 포맷팅을 "개선"하지 마라.
- 깨지지 않은 것을 리팩토링하지 마라.
- 기존 스타일에 맞춰라.
- 무관한 dead code를 발견하면 언급하라 - 삭제하지 마라.
- 네 변경으로 unused가 된 것만 제거하라.
- **변경된 모든 줄이 사용자의 요청에 직접 연결되어야 한다.**

### 4. Goal-Driven Execution
- 작업을 검증 가능한 목표로 변환하라.
- 다단계 작업에는 `[단계] → 검증: [확인사항]` 형식의 계획을 제시하라.
- 강한 성공 기준으로 독립적으로 반복할 수 있게 하라.

> 출처: [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | 상세: `~/.claude/guides/karpathy-guidelines.md`

---

## Claude 역할 정의

Claude는 이 프로젝트에서 **신중한 시니어 엔지니어의 관점**으로 행동한다.

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
| **Composable** | UI 렌더링 (Contract 직접 참조) | - | 필수 |
| **Info/Data (Interface)** | 공통 스펙 정의 + 기본값 제공 (Contract) | - | 다중 도메인 시 필수 |
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
├── PriceWithCouponInfo.kt       # interface (기본값 제공, Contract)

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
    ▼ Factory/Mapper.from(...)
[Info/Data] ← Contract (Interface 또는 data class)
    │
    ▼ 직접 참조 (별도 변환 계층 없음)
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

**Composable 사용 (Contract 직접 참조)**
```kotlin
@Composable
fun PriceWithCouponCompose(
    info: PriceWithCouponInfo,  // Contract 직접 참조
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.semantics {
            contentDescription = info.createDescriptionText()
        }
    ) {
        // info의 프로퍼티를 직접 참조하여 렌더링
        // 별도 UiModel/toComposeData() 변환 없이 간결하게 유지
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

Preview 파일은 **debug 소스셋**에 동일 패키지 경로로 배치 (release 빌드에서 제외):

```
src/main/java/.../priceWithCoupon/
├── PriceWithCouponCompose.kt
└── PriceWithCouponInfo.kt

src/debug/java/.../priceWithCoupon/
└── PriceComposePreview.kt
```

**Preview 작성**
```kotlin
// debug/.../PriceComposePreview.kt
@Preview(showBackground = true)
@Preview(showBackground = true, widthDp = 160)  // 다양한 사이즈
@Preview(showBackground = true, widthDp = 104)
@Composable
fun PriceTextPreview() {
    PriceWithCouponCompose(info = testPriceInfo)
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
// debug/.../PriceComposePreview.kt (테스트 데이터 + Provider + Preview를 한 파일에)
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
- `@Preview` 함수는 **debug** 소스셋에만 배치 (release 빌드에서 제외)
- 테스트 데이터 + PreviewParameterProvider + Preview 함수를 하나의 파일에 배치
- 다양한 사이즈/상태를 커버하는 Preview 작성
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

// Composable에서 semantics 적용 (Contract 직접 참조)
Column(
    modifier = modifier.clearAndSetSemantics {
        contentDescription = info.createDescriptionText()
    }
) {
    // 하위 요소들은 clearAndSetSemantics { } 로 접근성에서 제외
    Text(
        text = info.discountRateDisplayText?.text.orEmpty(),
        modifier = Modifier.clearAndSetSemantics { }
    )
}
```

---

#### 12. Composable-Contract 연결

- Composable은 Contract(Info/Data) interface를 **직접 참조**하여 렌더링
- 별도 UiModel이나 toComposeData() 변환 계층 없이 간결하게 유지
- 포맷팅(NumberFormat 등)은 Composable 내부에서 처리

```kotlin
@Composable
fun TransactionCardCompose(
    info: TransactionCardInfo,  // Contract 직접 참조
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val numberFormat = NumberFormat.getNumberInstance(Locale.KOREA)
    // info의 프로퍼티를 직접 참조하여 렌더링
}
```

---

Claude는 Compose 관련 질문에 대해:
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

Claude는 RecyclerView/Paging 질문 시:
- 이론적 이상 상태보다
- **실제 운영 중 발생 가능한 리스크**를 우선 설명해야 한다.

---

## 레거시 코드 관점

이 프로젝트는 단일 기능 최적화보다 **전체 시스템 안정성**을 더 중요하게 본다.

### Claude가 제공해야 하는 도움
- 긴 코드, 로그, PR diff 분석
- 기존 코드의 의도와 역사적 배경 추론
- 리팩토링의 부작용과 전파 범위 설명
- 팀 설득용 기술적 근거 정리

### Claude가 피해야 하는 것
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

## Claude 작업 범위

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

Claude가 로그를 추가할 때 이 형식을 따른다.

### 디버깅 작업 규칙

- 사용자가 "동일하게 발생해" 또는 "문제가 해결되지 않았어"라고 응답하면 해당 수정을 **즉시 원복**
- 원복 후 다른 접근법 시도

---

## 작업 완료 규칙

### 셀프 리뷰 필수

**모든 작업 완료 후** 아래 절차를 수행한다:

1. 변경된 코드를 다시 **Read**로 읽어서 검토
2. 문제 발견 시 **즉시 수정** (불필요한 코드, 잘못된 로직, thread-safety 등)
3. 수정 완료 후 작업 완료 보고

> 셀프 리뷰 없이 작업 완료를 보고하지 않는다.

### Git 브랜치 규칙

**`develop` 또는 `master` 브랜치에서는 절대 직접 커밋/머지하지 않는다.**

1. 현재 브랜치가 `develop` 또는 `master`이면 **반드시 새 기능 브랜치를 생성**하여 작업
2. 작업 완료 후 커밋은 **기능 브랜치에서만** 수행
3. `develop`/`master`로의 머지는 **사용자가 명시적으로 요청한 경우에만** 수행
4. 사용자가 "develop에서 작업해"라고 직접 지시한 경우에만 예외

> 이 규칙을 어기면 히스토리가 꼬이고 복구가 어려워진다. 반드시 지킨다.

---

## PR 작성 가이드

### 중요 규칙

- **"PR 작성"** 요청 시: 텍스트로만 작성하여 사용자가 복사해서 사용할 수 있도록 제공한다. `gh pr create` 실행하지 않는다.
- **"PR 생성"** 요청 시: `gh pr create` 명령어로 직접 GitHub에 PR을 등록한다.

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
