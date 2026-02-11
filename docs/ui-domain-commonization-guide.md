# UI-도메인 공통화 작업 가이드

## 1) 목적
이 문서는 특정 프로젝트 구조 설명이 아니라, **도메인 종속 없이 UI를 공통화하는 표준 작업 방식**을 정의한다.

> **이 구조의 목적**: 도메인 비즈니스 로직의 변경이 UI 컴포넌트의 파손으로 이어지지 않도록 격리한다. 이를 통해 UI 공통 모듈은 순수하게 "그려지는 법"에만 집중하고, 도메인은 "무엇을 보여줄지"만 결정한다.

적용 범위:
- 조합형 UI (예: CardInfo처럼 여러 하위 컴포넌트를 묶는 경우)
- 타입분기형 UI (예: BottomAction의 Action 영역)

제외 범위:
- BottomAction의 `coupon` 및 `landing` 영역 — 서버 연동/트래킹/보안 정책이 Action과 크게 달라, 공통화 시 변경 비용이 높으므로 현 단계에서 제외

---

## 2) 핵심 정리: A/B는 다른 철학이 아니다
이전 문서의 A/B는 서로 다른 설계 철학이 아니라, **같은 공통화 패턴의 구현 형태 차이**다.

공통 본질은 하나다.
- `Contract`를 benchmarkable(공통 UI)에서 정의
- 도메인에서 `Factory/Mapper.from(...)`로 Contract로 변환
- Renderer(Compose/View)는 Contract만 렌더
- 이벤트는 Intent로 상위에 전달

형태만 다르다.
- 조합형: 여러 하위 Contract를 하나의 상위 Contract로 묶음
- 타입분기형: sealed 타입으로 분기하고 Router가 타입별 렌더링

---

## 3) 공통 아키텍처

```text
[Domain Raw Model]
      |
      v
[Factory/Mapper.from(...)]   // 도메인 모듈
      |
      v
[UI Contract Model]          // benchmarkable
      |
      v
[Renderer(View/Compose)]     // benchmarkable
      |
      v
[Intent -> Upper Layer Side Effect]
```

### 3.1 업데이트 기준 역할 분리(상세)

#### Contract
- 책임: UI 렌더링에 필요한 최소 속성과 정책 API(`isNullOrEmpty`, `createDescriptionText`)를 정의
- 입력: 없음 (정의 계층)
- 출력: Renderer가 직접 소비하는 타입
- 하지 말아야 할 것: 도메인 모델 참조, 네트워크/트래킹 처리, 화면 맥락별 분기 로직

#### Factory/Mapper
- 책임: 도메인 모델을 Contract로 번역하고 비즈니스 규칙을 값으로 확정
- 입력: Domain Model + Params(환경값)
- 출력: Contract 인스턴스
- 하지 말아야 할 것: UI 위젯 제어, Compose/View API 호출, state 보관

#### Renderer (View/Compose)
- 책임: Contract를 화면으로 표현(노출/레이아웃/스타일)
- 입력: Contract + State
- 출력: UI 트리, Intent 이벤트 발생
- 하지 말아야 할 것: 도메인 필드 직접 해석, 사이드이펙트 실행

#### Intent
- 책임: 사용자 액션 결과를 순수 이벤트 모델로 상위 레이어에 전달
- 입력: 사용자 상호작용(클릭/토글/새로고침 등)
- 출력: Intent 객체(+ 필요 시 tracking payload)
- 하지 말아야 할 것: 자체적으로 상태 확정, 비즈니스 처리 실행

#### State
- 책임: UI 변화값 보관(`selectedPage`, `expanded` 등)
- 입력: Intent 처리 결과 또는 상위 reducer 결과
- 출력: 재렌더링에 필요한 현재 UI 상태
- 하지 말아야 할 것: 불변 입력값 보관, 도메인 원본 보관

#### Params
- 책임: 화면 컨텍스트의 불변 입력값 전달(`selectedTabIndex`, `itemMaxCount` 등)
- 입력: 상위 컨텍스트/호출부
- 출력: Factory/Mapper 계산 입력
- 하지 말아야 할 것: 사용자 상호작용에 따라 내부 값 변경

### 3.2 역할별 기존 코드 매핑 (현재 코드 기준)

| 역할 | CardInfo 영역 | BottomAction(Action 영역) |
|------|---------------|---------------------------|
| Contract | `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/itemcard/cardInfo/CardInfoData.kt` | `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/ActionButtonData.kt`, `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/action/ActionData.kt` |
| Factory/Mapper | `GmarketMobile/src/main/java/com/ebay/kr/main/domain/home/content/section/itemCard/cardInfo/HomeCardInfoData.kt` | `GmarketMobile/src/main/java/com/ebay/kr/main/domain/home/content/section/composable/common/bottomAction/HomeActionButtonDataFactory.kt`, `GmarketMobile/src/main/java/com/ebay/kr/main/domain/home/content/section/composable/common/bottomAction/action/HomeActionDataFactory.kt` |
| Renderer | `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/itemcard/cardInfo/CardInfoCompose.kt`, `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/itemcard/cardInfo/CardInfoView.kt` | `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/ActionButtonComposable.kt`, `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/action/ActionComposable.kt` |
| Intent | (CardInfo는 별도 Intent 없음) | `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/ActionButtonIntent.kt` |
| State | (CardInfo는 상태 최소) | `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/ActionButtonState.kt`, `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/action/ActionState.kt` |
| Params | (CardInfo는 from 인자 중심) | `benchmarkable/src/main/java/com/ebay/kr/gmarket/benchmarkable/common/bottomAction/action/ActionParams.kt`, `GmarketMobile/src/main/java/com/ebay/kr/main/domain/home/content/section/composable/common/bottomAction/HomeActionButtonParams.kt` |

---

## 4) 구현 변형 1: 조합형(Composite Contract)

### 4.1 적용 기준
- 한 UI 블록이 여러 하위 블록(Delivery/Labels/Review 등)을 합성할 때

### 4.2 템플릿

```kotlin
interface CompositeUiData {
    val sectionA: SectionAData?
    val sectionB: SectionBData?
    val sectionC: SectionCData?

    fun isNullOrEmpty(): Boolean =
        sectionA.isNullOrEmpty() && sectionB.isNullOrEmpty() && sectionC.isNullOrEmpty()

    fun createDescriptionText(): String = listOfNotNull(
        sectionA?.descriptionPart(),
        sectionB?.descriptionPart(),
        sectionC?.descriptionPart()
    ).filter { it.isNotBlank() }
        .joinToString(", ")
}
```

```kotlin
data class FeatureCompositeUiData(
    override val sectionA: SectionAData?,
    override val sectionB: SectionBData?,
    override val sectionC: SectionCData?
) : CompositeUiData {
    companion object {
        fun from(domain: FeatureModel): FeatureCompositeUiData {
            return FeatureCompositeUiData(
                sectionA = FeatureSectionAData.from(domain),
                sectionB = FeatureSectionBData.from(domain),
                sectionC = FeatureSectionCData.from(domain)
            )
        }
    }
}
```

핵심:
- 컨테이너는 조합만 담당
- 하위 섹션 계산은 각 하위 Factory로 분리

### 4.3 실제 코드: BottomAction 합 컴포넌트 (배타적 분기형)

조합형의 첫 번째 변형이다. 하위 컴포넌트(Action/Coupon/Landing) 중 **하나만 선택**해서 렌더링한다. 마커 인터페이스 + `when` 분기 Router로 구현한다.

**공통 UI 마커 인터페이스 (benchmarkable)**

```kotlin
@Immutable
interface ActionButtonData {
    val uts: UTSTrackingDataV2?
}
```

**합 State 컨테이너 (benchmarkable)** - Action State를 lazy하게 생성/보관

```kotlin
@Stable
class ActionButtonState {
    private var _action: ActionState? = null
    private var _coupon: ActionCouponState? = null
    private var _landing: ActionLandingState? = null

    fun action(): ActionState =
        _action ?: ActionState().also { _action = it }
    fun coupon(): ActionCouponState =
        _coupon ?: ActionCouponState().also { _coupon = it }
    fun landing(): ActionLandingState =
        _landing ?: ActionLandingState().also { _landing = it }

    fun resetForContextChange() {
        _action?.resetForContextChange()
    }
}
```

**합 Intent (benchmarkable)** - 하위 Intent를 하나의 sealed로 묶음

```kotlin
@Immutable
sealed interface ActionButtonIntent {
    sealed interface ActionIntent : ActionButtonIntent {
        data class Landing(val url: String?) : ActionIntent
        data class RefreshPage(val totalCount: Int) : ActionIntent
        data class SetExpanded(val expanded: Boolean) : ActionIntent
    }
    sealed interface CouponIntent : ActionButtonIntent {
        data class RequestCoupon(val url: String) : CouponIntent
    }
}
```

**합 Router Composable (benchmarkable)** - Data 타입에 따라 하위 Composable로 라우팅

```kotlin
@Composable
fun ActionButtonComposable(
    actionButtonData: ActionButtonData,
    actionButtonState: ActionButtonState,
    modifier: Modifier = Modifier,
    onAction: (ActionButtonIntent, UTSTrackingDataV2?) -> Unit
) {
    when (actionButtonData) {
        is ActionCouponData -> ActionCouponComposable(
            data = actionButtonData,
            state = actionButtonState.coupon(),
            modifier = modifier, onAction = onAction
        )
        is ActionLandingData -> ActionLandingComposable(
            data = actionButtonData,
            state = actionButtonState.landing(),
            modifier = modifier, onAction = onAction
        )
        is ActionData -> ActionComposable(
            data = actionButtonData,
            state = actionButtonState.action(),
            modifier = modifier, onAction = onAction
        )
    }
}
```

**도메인 최상위 Factory (Home)** - 버튼 타입 판단 후 하위 Factory에 위임

```kotlin
object HomeActionButtonDataFactory {
    fun from(
        itemTemplateModel: ItemTemplateModel,
        params: HomeActionButtonParams
    ): ActionButtonData? {
        return if (itemTemplateModel.actionButton != null) {
            when {
                itemTemplateModel.actionButton.couponEventData != null ->
                    ActionCouponDataImpl.from(itemTemplateModel.actionButton)
                itemTemplateModel.actionButton.urlLandingData != null ->
                    ActionLandingDataImpl.from(itemTemplateModel.actionButton)
                else -> null
            }
        } else {
            HomeActionDataFactory.from(
                itemTemplateModel = itemTemplateModel,
                params = params.action
            )
        }
    }
}
```

**도메인 Params 컨테이너 (Home)** - 하위 타입별 Params를 묶음

```kotlin
@Immutable
data class HomeActionButtonParams(
    val action: ActionParams = ActionParams()
)
```

핵심:
- 합 컴포넌트는 **마커 인터페이스 + State 컨테이너 + Intent 합 + Router**로 구성
- 도메인은 **최상위 Factory + Params 컨테이너**로 구성
- 하위 컴포넌트의 세부 구현은 각각 독립적

### 4.4 실제 코드: CardInfo 조합 컴포넌트 (공존형 합성)

4.3의 BottomAction이 "하나를 고르는" 구조였다면, CardInfo는 정반대다. DeliveryTags/InfoLabels/Review 세 하위 컴포넌트를 **모두 함께 렌더링**하는 공존형 조합이다.
BottomAction(4.3)이 하나만 선택하는 배타적 분기라면, CardInfo는 **있는 것은 모두 보여주는** 순수 합성이다.

> **왜 하위 Contract이 interface인가?**
> `InfoLabelsData`의 `showBackgroundCheckWithBorder`처럼, 같은 프로퍼티라도 **도메인별 레이아웃 정책이 다른** 경우가 있다 (Home: `true`, Search: `false`). 또한 `createDescriptionText()`처럼 접근성 텍스트 생성 로직도 도메인이 override할 수 있어야 한다. 따라서 섹션 6의 판단 플로우에서 "getter에서 도메인 원본을 참조해 계산하는가? → YES" 경로에 해당하여 interface를 사용한다. 단, 도메인 구현체는 `data class`로 작성하여 불변성을 확보한다.

**합 Contract (benchmarkable)** — 하위 컴포넌트를 optional 프로퍼티로 조합

```kotlin
interface CardInfoData {
    val itemScaleType: ItemScaleType

    val deliveryTagsData: DeliveryTagsData?
        get() = null
    val infoLabelsData: InfoLabelsData?
        get() = null
    val reviewData: InfoReviewData?
        get() = null

    fun isNullOrEmpty(): Boolean =
        deliveryTagsData.isNullOrEmpty() &&
        reviewData.isNullOrEmpty() &&
        infoLabelsData.isNullOrEmpty()

    fun createDescriptionText(): String {
        return StringBuilder().apply {
            deliveryTagsData?.let { append(it.createDescriptionText()) }
            reviewData?.let { append(it.createDescriptionText()) }
            infoLabelsData?.let { append(it.createDescriptionText()) }
        }.toString()
    }
}
```

**하위 Contract 1: DeliveryTagsData (benchmarkable)** — 배송 태그 + 관세 정보

```kotlin
interface DeliveryTagsData {
    val deliveryTags: ImmutableList<ImageDisplayText>?
        get() = null
    val customsInfoListItem: CustomsInfoListItem?
        get() = null

    fun createDescriptionText(): String {
        val deliveryTagsDescription = deliveryTags?.joinToString { content ->
            val imageDescription = content.image?.altText ?: ""
            val textDescription = content.text?.text ?: ""
            "$imageDescription  $textDescription"
        } ?: ""
        val customsInfoDescription = customsInfoListItem?.displayText?.text ?: ""
        return "$deliveryTagsDescription $customsInfoDescription"
    }
}

fun DeliveryTagsData?.isNullOrEmpty(): Boolean {
    return this?.deliveryTags.isNullOrEmpty()
}
```

**하위 Contract 2: InfoLabelsData (benchmarkable)** — LMO 라벨 목록 + 레이아웃 설정

```kotlin
interface InfoLabelsData {
    val itemScaleType: ItemScaleType?
        get() = null
    val infoLabels: ImmutableList<ImageDisplayContent>?
        get() = null
    val isGridInFlexbox: Boolean
        get() = true
    val maxLines: Int
        get() = Int.MAX_VALUE
    val showBackgroundCheckWithBorder: Boolean
        get() = true

    fun createDescriptionText(): String {
        return infoLabels?.joinToString { content ->
            val imageDescription = content.image?.altText ?: ""
            val textDescription = content.text?.joinToString { it.text ?: "" } ?: ""
            "$imageDescription  $textDescription"
        } ?: ""
    }
}

fun InfoLabelsData?.isNullOrEmpty(): Boolean {
    return this?.infoLabels.isNullOrEmpty()
}
```

**하위 Contract 3: InfoReviewData (benchmarkable)** — GDS ReviewData 마커

```kotlin
interface InfoReviewData : ReviewData
```

GDS 디자인 시스템의 `ReviewData`를 상속하여 ItemCard 맥락임을 명시한다. 렌더링은 GDS `GDSReview`에 위임.

**합 Renderer (benchmarkable)** — Column으로 하위 Composable 조합 + Custom Content Slot

```kotlin
@Composable
fun CardInfoCompose(
    modifier: Modifier = Modifier,
    cardInfoData: CardInfoData,
    deliveryTagsCustomContent: (@Composable () -> Unit)? = null,
    infoLabelCustomContent: (@Composable () -> Unit)? = null,
    reviewCustomContent: (@Composable () -> Unit)? = null,
) {
    Column(modifier = modifier.fillMaxWidth()) {

        // 1. DeliveryTags
        val deliveryTagsData = cardInfoData.deliveryTagsData
        val showDeliveryTag = deliveryTagsCustomContent != null || !deliveryTagsData.isNullOrEmpty()

        if (deliveryTagsCustomContent != null) {
            deliveryTagsCustomContent()
        } else {
            deliveryTagsData?.let { DeliveryTagsCompose(it) }
        }

        // 2. InfoLabels (간격: 이전 섹션이 있으면 4dp)
        val infoLabelsData = cardInfoData.infoLabelsData
        val showInfoLabels = infoLabelCustomContent != null || !infoLabelsData.isNullOrEmpty()

        if (showInfoLabels && showDeliveryTag) {
            Spacer(modifier = Modifier.height(4.dp))
        }
        if (infoLabelCustomContent != null) {
            infoLabelCustomContent()
        } else {
            infoLabelsData?.let { InfoLabelsCompose(it) }
        }

        // 3. Review (간격: 이전 섹션에 따라 2dp 또는 4dp)
        val reviewData = cardInfoData.reviewData
        val showReview = reviewCustomContent != null || !reviewData.isNullOrEmpty()

        if (showReview) {
            if (showInfoLabels) {
                Spacer(modifier = Modifier.height(2.dp))
            } else if (showDeliveryTag) {
                Spacer(modifier = Modifier.height(4.dp))
            }
        }
        if (reviewCustomContent != null) {
            reviewCustomContent()
        } else {
            reviewData?.let { GDSReview(reviewData = it) }
        }
    }
}
```

**하위 Renderer: DeliveryTagsCompose (benchmarkable)**

```kotlin
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun DeliveryTagsCompose(
    deliveryTagsData: DeliveryTagsData,
    modifier: Modifier = Modifier
) {
    val tags = deliveryTagsData.deliveryTags.orEmpty()
    val hasTaxInfoItem = deliveryTagsData.customsInfoListItem.isNotNull()

    FlowRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.Start,
        verticalArrangement = Arrangement.Center,
    ) {
        tags.forEachIndexed { index, imageDisplayText ->
            DeliveryTagCompose(
                itemImageUrl = imageDisplayText.image?.imageUrl,
                itemTextDisplayText = imageDisplayText.text,
                showItemDivider = index != tags.lastIndex,
                showTaxInfoItemDivider = hasTaxInfoItem && index == tags.lastIndex,
            )
        }
        deliveryTagsData.customsInfoListItem?.let { taxInfoListItem ->
            CustomsInfoCompose(
                modifier = Modifier.align(Alignment.CenterVertically),
                customsInfoListItem = taxInfoListItem,
            )
        }
    }
}
```

**하위 Renderer: InfoLabelsCompose (benchmarkable)**

```kotlin
@Composable
fun InfoLabelsCompose(
    infoLabelsData: InfoLabelsData,
    horizontalSpacing: Dp = 2.dp,
    verticalSpacing: Dp = 2.dp
) {
    infoLabelsData.infoLabels?.let {
        MaxLineFlowRow(
            items = it.toImmutableList(),
            maxLines = infoLabelsData.maxLines,
            horizontalSpacing = horizontalSpacing,
            verticalSpacing = verticalSpacing
        ) { infoLabel ->
            InfoLabelCompose(
                imageDisplayContent = infoLabel,
                showBackgroundCheckWithBorder = infoLabelsData.showBackgroundCheckWithBorder
            )
        }
    }
}
```

**도메인 합 Factory (Home)** — 하위 Factory를 각각 호출하여 CardInfoData 조립

```kotlin
data class HomeCardInfoData(
    override val itemScaleType: ItemScaleType,
    override val reviewData: InfoReviewData? = null,
    override val infoLabelsData: InfoLabelsData? = null,
    override val deliveryTagsData: DeliveryTagsData? = null
) : CardInfoData {

    companion object {
        fun from(
            itemCard: ItemCard,
            itemScaleType: ItemScaleType,
            maxLines: Int = 2
        ): HomeCardInfoData = HomeCardInfoData(
            itemScaleType = itemScaleType,
            reviewData = if (itemScaleType != ItemScaleType.LARGE)
                HomeReviewData.from(itemCard, itemScaleType)
            else null,
            infoLabelsData = HomeInfoLabelsData.from(
                itemCard = itemCard,
                itemScaleType = itemScaleType,
                maxLines = maxLines
            ),
            deliveryTagsData = HomeDeliveryTagsData.from(itemCard)
        )
    }
}
```

**도메인 하위 Factory (Home)** — 각 하위 컴포넌트 생성

```kotlin
// DeliveryTags
data class HomeDeliveryTagsData(
    override val deliveryTags: ImmutableList<ImageDisplayText>?
) : DeliveryTagsData {
    companion object {
        fun from(itemCard: ItemCard): HomeDeliveryTagsData = HomeDeliveryTagsData(
            deliveryTags = itemCard.metaLabels?.map {
                ImageDisplayText(text = it.text?.get(0), image = it.image)
            }?.toImmutableList()
        )
    }
}

// InfoLabels
data class HomeInfoLabelsData(
    override val infoLabels: ImmutableList<ImageDisplayContent>? = null,
    override val itemScaleType: ItemScaleType,
    override val isGridInFlexbox: Boolean = true,
    override val maxLines: Int = Int.MAX_VALUE,
    override val showBackgroundCheckWithBorder: Boolean = true
) : InfoLabelsData {
    companion object {
        fun from(
            itemCard: ItemCard,
            itemScaleType: ItemScaleType,
            isGridInFlexbox: Boolean = true,
            maxLines: Int = 2
        ): HomeInfoLabelsData = HomeInfoLabelsData(
            infoLabels = itemCard.infoLabels?.toImmutableList(),
            itemScaleType = itemScaleType,
            isGridInFlexbox = isGridInFlexbox,
            maxLines = if (itemScaleType == ItemScaleType.LARGE) 1 else maxLines
        )
    }
}

// Review
data class HomeReviewData(
    override val itemScaleType: ItemScaleType,
    override val avgStarScore: String?,
    override val feedbackCount: String?,
) : InfoReviewData {
    companion object {
        fun from(
            itemCard: ItemCard,
            itemScaleType: ItemScaleType = ItemScaleType.LARGE
        ): HomeReviewData = HomeReviewData(
            itemScaleType = itemScaleType,
            avgStarScore = itemCard.reviewPoint?.starPoint?.toString(),
            feedbackCount = itemCard.reviewPoint?.reviewCount,
        )
    }
}
```

**다중 도메인 참고: Search 도메인** — 동일 패턴이나 toggle flag 제공

```kotlin
data class LpSrpCardInfoData(
    override val itemScaleType: ItemScaleType,
    override val deliveryTagsData: DeliveryTagsData?,
    override val infoLabelsData: InfoLabelsData? = null,
    override val reviewData: InfoReviewData? = null,
) : CardInfoData {

    companion object {
        fun from(
            itemCard: ItemCardGeneralViewModelData?,
            itemScaleType: ItemScaleType,
            showDeliveryTags: Boolean = true,
            showInfoLabels: Boolean = true,
            showReview: Boolean = true,
            showPayCount: Boolean = true
        ): LpSrpCardInfoData = LpSrpCardInfoData(
            itemScaleType = itemScaleType,
            deliveryTagsData = if (showDeliveryTags) LpSrpDeliveryTagsData.from(itemCard) else null,
            infoLabelsData = if (showInfoLabels) LpSrpInfoLabelsData.from(itemCard) else null,
            reviewData = if (showReview) LpSrpReviewData.from(itemCard, itemScaleType, showPayCount) else null
        )
    }
}
```

**데이터 흐름**

```text
[ItemCard] (도메인 원본)
    ↓ HomeCardInfoData.from(itemCard, itemScaleType, maxLines)
    ├── HomeDeliveryTagsData.from(itemCard)         → DeliveryTagsData
    ├── HomeInfoLabelsData.from(itemCard, scale, maxLines) → InfoLabelsData
    └── HomeReviewData.from(itemCard, scale)        → InfoReviewData
    ↓
[CardInfoData] (interface)
    ↓
[CardInfoCompose]
    ├── DeliveryTagsCompose → DeliveryTagCompose (리스트) + CustomsInfoCompose
    ├── InfoLabelsCompose   → InfoLabelCompose (리스트)
    └── GDSReview           → GDS 디자인 시스템 리뷰 컴포넌트
```

핵심:
- **공존형 합성**: 하위 컴포넌트가 모두 동시에 렌더링됨 (BottomAction의 배타적 분기와 대비)
- **Custom Content Slot**: 도메인별로 특정 섹션만 커스텀 UI로 교체 가능
- **간격 관리 중앙화**: CardInfoCompose가 하위 섹션 간 간격을 일괄 관리
- **Stateless**: Intent/State 없이 순수 렌더링만 담당
- **다중 도메인 Factory**: 각 도메인이 동일 Contract에 대해 자체 Factory 보유

### 4.5 조합 패턴 비교: BottomAction vs CardInfo

| 구분 | BottomAction (4.3) | CardInfo (4.4) |
|------|-------------------|----------------|
| 합 방식 | 마커 인터페이스 + `when` 분기 Router | 하위 Data를 프로퍼티로 조합 |
| 하위 관계 | **배타적** (하나만 렌더링) | **공존** (모두 렌더링) |
| State | 합 State 컨테이너 (lazy 생성) | 없음 (stateless) |
| Intent | 합 Intent (sealed union) | 없음 |
| Custom Slot | 없음 | 하위별 커스텀 컨텐츠 슬롯 |
| 간격 관리 | 불필요 (하나만 렌더링) | 합 Composable이 중앙 관리 |
| 접근성 | 각 하위 Contract에서 개별 처리 | 합 Contract가 하위 설명을 취합 |
| 다중 도메인 | 단일 최상위 Factory | 도메인별 data class Factory |

공존형 vs 배타적 선택 기준:
- 하위 컴포넌트가 **동시에 보여야** 하면 → CardInfo 패턴 (프로퍼티 조합)
- 하위 컴포넌트 중 **하나만 선택**되면 → BottomAction 패턴 (마커 인터페이스 + Router)

---

## 5) 구현 변형 2: 타입분기형(Polymorphic Contract)

섹션 4에서는 **여러 컴포넌트를 묶는** 조합 패턴을 다뤘다. 이번 섹션은 그 반대 시점이다 — **하나의 자리에서 타입별로 다른 UI를 렌더링**하는 패턴이다. 4.3 BottomAction의 **하위 컴포넌트**(Action 영역)가 바로 이 패턴으로 구현되어 있다.

### 5.1 적용 기준
- 같은 자리의 UI가 타입별로 다른 모양/행동(Landing/Refresh/Expand 등)을 가질 때

### 5.2 템플릿

```kotlin
interface ActionBaseData {
    val tracking: Tracking?
}

sealed interface FeedActionData : ActionBaseData {
    data class Landing(
        override val tracking: Tracking?,
        val url: String?,
        val text: String?
    ) : FeedActionData

    data class Refresh(
        override val tracking: Tracking?,
        val totalPageCount: Int,
        val text: String?
    ) : FeedActionData

    data class Expand(
        override val tracking: Tracking?
    ) : FeedActionData
}

@Immutable
data class FeedActionParams(
    val selectedTabIndex: Int,
    val itemMaxCount: Int,
    val totalItemCount: Int,
    val isRefresh: Boolean,
)

@Stable
class FeedActionState {
    var selectedPage: Int = 0
        private set
    var expanded: Boolean = false
        private set

    fun setExpanded(value: Boolean) { expanded = value }

    fun advancePage(totalCount: Int): Int {
        val safe = totalCount.coerceAtLeast(0)
        if (safe <= 0) return 0.also { selectedPage = it }
        selectedPage = (selectedPage + 1) % safe
        return selectedPage
    }

    fun resetForContextChange() {
        selectedPage = 0
        expanded = false
    }
}

sealed interface FeedActionIntent {
    data class Landing(val url: String?) : FeedActionIntent
    data class RefreshPage(val totalCount: Int) : FeedActionIntent
    data class SetExpanded(val expanded: Boolean) : FeedActionIntent
}
```

```kotlin
@Composable
fun FeedActionRouter(
    data: FeedActionData,
    state: FeedActionState,
    onIntent: (FeedActionIntent, Tracking?) -> Unit
) {
    when (data) {
        is FeedActionData.Landing -> { /* landing UI */ }
        is FeedActionData.Refresh -> { /* refresh UI */ }
        is FeedActionData.Expand -> { /* expand UI */ }
    }
}
```

핵심:
- 타입 판정은 `Factory` + `Router` 두 지점으로 제한
- side-effect는 Router가 아니라 상위가 처리

### 5.3 실제 코드: Action 하위 컴포넌트

4.3에서 BottomAction 합 컴포넌트의 `ActionData` 분기가 어떻게 타입분기형으로 구현되는지 보여준다. Action 영역은 Landing/Refresh/Expand 세 가지 타입으로 분기한다.

**Contract: sealed interface + data class (benchmarkable)**

```kotlin
@Immutable
sealed interface ActionData : ActionButtonData {
    val imagePosition: ImagePosition
    val colorCode: String?

    @Immutable
    data class ActionLandingData(
        override val imagePosition: ImagePosition = ImagePosition.RIGHT,
        override val uts: UTSTrackingDataV2?,
        override val colorCode: String?,
        val landingUrl: String? = null,
        val textBtn: String? = null,
        val useViewAllText: Boolean = true,
    ) : ActionData

    @Immutable
    data class ActionRefreshData(
        override val imagePosition: ImagePosition = ImagePosition.LEFT,
        override val uts: UTSTrackingDataV2?,
        override val colorCode: String?,
        val textBtn: String? = null,
        val isRefreshLabel: Boolean,
        val totalPageCount: Int,
    ) : ActionData

    @Immutable
    data class ActionExpandData(
        override val imagePosition: ImagePosition = ImagePosition.RIGHT,
        override val uts: UTSTrackingDataV2?,
        override val colorCode: String?,
    ) : ActionData
}
```

**Params (benchmarkable)** - 불변 입력 파라미터

```kotlin
@Immutable
data class ActionParams(
    val selectedTabIndex: Int = 0,
    val itemMaxCount: Int = 1,
    val isRefresh: Boolean = false,
    val useRefreshLabel: Boolean = true,
    val useViewAllText: Boolean = true,
    val totalItemCount: Int = 0
)
```

**State (benchmarkable)** - UI 상태

```kotlin
@Stable
class ActionState {
    var selectedPage by mutableIntStateOf(0)
        private set
    var expanded by mutableStateOf(false)
        private set

    fun updateExpanded(value: Boolean) { expanded = value }

    fun advancePage(totalCount: Int): Int {
        val tc = totalCount.coerceAtLeast(0)
        if (tc <= 0) { selectedPage = 0; return selectedPage }
        val next = selectedPage + 1
        selectedPage = if (next < tc) next else 0
        return selectedPage
    }

    fun resetForContextChange() {
        selectedPage = 0
        expanded = false
    }
}
```

**Intent** — 4.3의 `ActionButtonIntent.ActionIntent`를 그대로 사용 (중복 정의 없음)

**Router Composable (benchmarkable)** - Data 타입에 따라 하위 Composable로 라우팅

```kotlin
@Composable
fun ActionComposable(
    data: ActionData,
    state: ActionState,
    modifier: Modifier = Modifier,
    onAction: (ActionButtonIntent.ActionIntent, UTSTrackingDataV2?) -> Unit
) {
    when (data) {
        is ActionData.ActionExpandData -> ActionExpand(data, state, modifier, onAction)
        is ActionData.ActionLandingData -> ActionLanding(data, modifier, onAction)
        is ActionData.ActionRefreshData -> ActionRefresh(data, state, modifier, onAction)
    }
}

// 각 하위 Composable은 private으로 선언
@Composable
private fun ActionExpand(data: ActionData.ActionExpandData, state: ActionState, ...) {
    val isExpanded = state.expanded
    GDSActionButton(
        actionButtonType = ActionButtonType.Expand(text = ..., isExpand = isExpanded, ...)
    ) {
        onAction(ActionButtonIntent.ActionIntent.SetExpanded(!isExpanded), data.uts)
    }
}

@Composable
private fun ActionLanding(data: ActionData.ActionLandingData, ...) {
    GDSActionButton(
        actionButtonType = ActionButtonType.Action(text = ..., prefixText = ..., ...)
    ) {
        onAction(ActionButtonIntent.ActionIntent.Landing(data.landingUrl), data.uts)
    }
}

@Composable
private fun ActionRefresh(data: ActionData.ActionRefreshData, state: ActionState, ...) {
    val pageIndex = state.selectedPage.coerceIn(0, data.totalPageCount - 1)
    GDSActionButton(
        actionButtonType = ActionButtonType.Refresh(text = "${pageIndex+1}/${data.totalPageCount}", ...)
    ) {
        onAction(ActionButtonIntent.ActionIntent.RefreshPage(data.totalPageCount), data.uts)
    }
}
```

**도메인 Factory (Home)** - 도메인 모델을 ActionData data class로 직접 변환

```kotlin
object HomeActionDataFactory {
    fun from(
        bottomButtonComponentModel: BottomButtonComponentModel,
        params: ActionParams,
    ): ActionData? {
        val uts = bottomButtonComponentModel.uts
        val colorCode = bottomButtonComponentModel.selectedColorCode
        val text = bottomButtonComponentModel.text.orEmpty()
        val landingUrl = bottomButtonComponentModel.value
        val hasLanding = !landingUrl.isNullOrEmpty()

        return if (params.isRefresh) {
            val perPage = params.itemMaxCount.coerceAtLeast(1)
            val totalPageCount = if (params.totalItemCount <= 0) 0
                else (params.totalItemCount + perPage - 1) / perPage
            ActionData.ActionRefreshData(
                uts = uts, colorCode = colorCode, textBtn = text,
                totalPageCount = totalPageCount.coerceAtLeast(1),
                isRefreshLabel = params.useRefreshLabel
            )
        } else if (hasLanding) {
            ActionData.ActionLandingData(
                uts = uts, colorCode = colorCode,
                landingUrl = landingUrl, textBtn = text,
                useViewAllText = params.useViewAllText
            )
        } else {
            ActionData.ActionExpandData(uts = uts, colorCode = colorCode)
        }
    }
}
```

핵심:
- **data class 패턴**: benchmarkable에서 sealed interface + data class로 확정, 도메인 Factory에서 직접 생성
- **Private 하위 Composable**: Router만 public, 각 타입별 UI는 private
- **Intent 발행**: 클릭 시 Intent만 전달, side-effect는 상위에서 처리

---

## 6) data class vs interface 선택 기준

기본 원칙: **프로퍼티 구조가 고정이면 data class를 기본값으로 채택**한다.

`data class`가 적합한 경우:
- 도메인별 차이가 값의 차이만 있음
- Contract의 프로퍼티 구조는 고정
- Factory에서 값 계산 후 주입하면 끝

`interface + sealed mapper`가 적합한 경우:
- 타입별 getter 계산 로직이 크게 다름
- 원본 도메인 보관 + lazy 계산이 필요
- 케이스 추가가 잦고 타입별 분리가 필요

실무 권장:
- 새 컴포넌트는 data class 우선
- 복잡한 가격/프로모션 엔진처럼 계산 복잡도가 높을 때만 interface+sealed 선택

### 판단 플로우

```text
Q: Contract 프로퍼티가 모든 도메인에서 동일한가?
|
+-- YES --> data class (Factory에서 값만 주입)
|
+-- NO  --> Q: getter에서 도메인 원본을 참조해 계산하는가?
            |
            +-- YES --> interface + sealed class Mapper
            |           (타입별 계산 로직 캡슐화)
            |
            +-- NO  --> data class
                        (Factory에서 변환 후 주입)
```

핵심:
- "도메인마다 **값**이 다르다" → data class (Factory에서 값 확정)
- "도메인별 **레이아웃 정책이나 표현 다형성**이 필요하다" → interface (도메인이 override)
- "lazy 계산이 필요하다"는 interface의 이유가 아님 → 그건 Factory/State로 이동시킨다

---

## 7) 팀 공통 룰

1. benchmarkable(UI 공통 모듈)에서 도메인 모델 import 금지
2. 도메인 -> Contract 변환은 `from(...)`/`Factory`로 단일화
3. Renderer에는 비즈니스 분기/데이터 가공 금지
4. Params(입력)와 State(변화값)를 절대 섞지 않기
5. 클릭 처리 side-effect는 상위 레이어에서만 실행
6. 접근성 설명문 생성 책임은 Contract에 두기
7. View/Compose 정책 동등성 유지(노출/간격/최대라인)
8. 타입 분기는 **Factory + Router 2단으로 제한** — Renderer 내부에서 `when(data)` 재분기 금지
9. Renderer 하위 Composable은 **private** — Router만 public으로 노출

### 7.1 경계 위반 구체 예시

```kotlin
// ❌ Contract에서 비즈니스 규칙 계산
interface PriceData {
    val rawPrice: Long
    val discountRate: Int
    val finalPrice: Long
        get() = rawPrice * (100 - discountRate) / 100  // 가격 계산은 도메인 책임
}

// ✅ Factory에서 계산 후 값만 전달
data class PriceUiModel(
    val discountRateText: String?,    // "17%"
    val finalPriceText: String,       // "9,999원"
)
```

```kotlin
// ❌ Renderer에서 도메인 의미 해석
@Composable
fun ItemLabel(data: InfoLabelsData) {
    if (data.infoLabels?.any { it.type == "SOLD_OUT" } == true) {  // 도메인 규칙 침범
        SoldOutOverlay()
    }
}

// ✅ Renderer는 Contract가 제공한 값만 사용
@Composable
fun ItemLabel(data: InfoLabelsData) {
    data.infoLabels?.forEach { label ->
        InfoLabelCompose(imageDisplayContent = label)  // 표현만 담당
    }
}
```

```kotlin
// ❌ Factory에서 UI 정책(간격/스타일) 결정
fun from(...) = HomeInfoLabelsData(
    topPadding = 4.dp,  // UI 간격은 Renderer 책임
)

// ✅ Factory는 데이터 정책만 결정
fun from(...) = HomeInfoLabelsData(
    maxLines = if (itemScaleType == ItemScaleType.LARGE) 1 else 2,  // 데이터 정책
)
```

### 7.2 State 생명주기

State는 **ViewHolder의 라이프사이클을 따른다.**

```text
ViewHolder 생성 → remember { State() }
    ↓
bind(item) → 아이템 key 변경 시 state.resetForContextChange()
    ↓
사용자 인터랙션 → state.advancePage() / state.updateExpanded()
    ↓
ViewHolder 재활용 → bind(다른 item) → resetForContextChange()
```

규칙:
- State는 ViewHolder(또는 `remember`)에서 생성, Factory에서 생성하지 않음
- 아이템 key가 변경되면 반드시 `resetForContextChange()` 호출
- Process recreation 시 State 복원은 **기본적으로 불필요** — 리스트 스크롤로 ViewHolder가 재활용될 때 어차피 reset됨 (11.3 참고)

---

## 8) 코드 리뷰 체크리스트

- [ ] UI 모듈이 도메인 모델을 직접 참조하지 않는가?
- [ ] 변환 로직이 Factory/Mapper 한곳으로 수렴되는가?
- [ ] Renderer가 Contract만 다루는가?
- [ ] Params/State/Intent 역할이 분리되어 있는가?
- [ ] 타입 분기 지점이 Factory/Router로 제한되어 있는가?
- [ ] A11y 문장이 Contract 기반으로 일관 생성되는가?

---

## 9) 안티패턴 -> 교정

1. Renderer에서 도메인 필드 직접 참조
- 교정: 도메인에서 Contract로 변환 후 전달

2. UI 클릭 핸들러에서 바로 네트워크/화면이동 실행
- 교정: Intent만 전달하고 상위에서 side-effect 처리

3. 호출부마다 임시 매핑 반복
- 교정: Factory/Mapper 단일 진입점 사용

4. totalCount, selectedPage, expanded를 한 객체에 혼합
- 교정: Params/State 분리

5. 프로퍼티 동일한데 interface + 도메인별 구현체를 쓰는 경우
- 교정: data class로 확정하고 도메인에서는 Factory로 생성만 수행

---

## 10) 테스트 최소 세트

1. Factory/Mapper 테스트: 도메인 입력 -> Contract 출력 검증
2. State 테스트: `advancePage`, `setExpanded`, `resetForContextChange`
3. Intent 테스트: 클릭별 Intent + tracking 전달 검증
4. A11y 테스트: description 누락/중복/구분자 검증
5. Renderer 테스트: View/Compose 정책 동등성 검증

---

## 11) 확장 고려 사항

현재 가이드가 다루는 영역은 **구조 설계**에 집중되어 있다. 아래는 이 패턴을 운영 수준으로 끌어올릴 때 고려할 확장 포인트다.

- **필수**: 11.2 Factory 단위 테스트, 11.4 Contract 하위 호환 전략
- **권장**: 11.1 Factory 에러 핸들링, 11.5 성능 측정 기준, 11.6 마이그레이션 가이드
- **선택**: 11.3 State 스냅샷 저장/복원 (대부분의 리스트 UI에서 불필요)

### 11.1 Factory 에러 핸들링

현재 Factory는 변환 실패 시 `null`을 반환한다. 운영 환경에서는 "왜 null인지" 추적이 필요하다.

```kotlin
// 현재: null 반환만
object HomeActionDataFactory {
    fun from(...): ActionData? {
        val tabComponent = itemTemplateModel.tabs?.getOrNull(params.selectedTabIndex)
            ?: return null  // 왜 null인지 알 수 없음
    }
}

// 확장: Result 또는 로깅 추가
object HomeActionDataFactory {
    fun from(...): ActionData? {
        val tabComponent = itemTemplateModel.tabs?.getOrNull(params.selectedTabIndex)
        if (tabComponent == null) {
            Log.w(TAG, "ActionData creation failed: tab index ${params.selectedTabIndex} out of bounds (tabs size: ${itemTemplateModel.tabs?.size})")
            return null
        }
        // ...
    }
}
```

고려 사항:
- `null` 반환은 UI에서 "안 보임"으로 처리되므로 당장 크래시는 없지만, 디버깅이 어려움
- 모든 Factory에 일괄 적용할 필요는 없고, **데이터가 내려왔는데 UI가 안 보이는** 이슈가 반복되는 지점에 선택적으로 추가
- Release 빌드에서는 로그 레벨 조절 또는 제거

### 11.2 Factory 단위 테스트

Factory는 순수 함수(입력 → 출력)이므로 테스트 작성이 가장 쉬운 구간이다.

```kotlin
class HomeActionDataFactoryTest {

    @Test
    fun `isRefresh가 true이면 ActionRefreshData를 반환한다`() {
        val button = BottomButtonComponentModel(text = "새로 보기", value = null, uts = null)
        val params = ActionParams(isRefresh = true, itemMaxCount = 4, totalItemCount = 12)

        val result = HomeActionDataFactory.from(button, params)

        assertThat(result).isInstanceOf(ActionData.ActionRefreshData::class.java)
        assertThat((result as ActionData.ActionRefreshData).totalPageCount).isEqualTo(3)
    }

    @Test
    fun `landingUrl이 있으면 ActionLandingData를 반환한다`() {
        val button = BottomButtonComponentModel(text = "전체보기", value = "https://...", uts = null)
        val params = ActionParams(isRefresh = false)

        val result = HomeActionDataFactory.from(button, params)

        assertThat(result).isInstanceOf(ActionData.ActionLandingData::class.java)
        assertThat((result as ActionData.ActionLandingData).landingUrl).isEqualTo("https://...")
    }

    @Test
    fun `landingUrl이 없고 isRefresh가 false이면 ActionExpandData를 반환한다`() {
        val button = BottomButtonComponentModel(text = null, value = null, uts = null)
        val params = ActionParams(isRefresh = false)

        val result = HomeActionDataFactory.from(button, params)

        assertThat(result).isInstanceOf(ActionData.ActionExpandData::class.java)
    }

    @Test
    fun `totalItemCount가 0이면 totalPageCount는 최소 1이다`() {
        val button = BottomButtonComponentModel(text = null, value = null, uts = null)
        val params = ActionParams(isRefresh = true, itemMaxCount = 4, totalItemCount = 0)

        val result = HomeActionDataFactory.from(button, params) as ActionData.ActionRefreshData

        assertThat(result.totalPageCount).isEqualTo(1)
    }
}
```

```kotlin
class ActionStateTest {

    @Test
    fun `advancePage는 순환한다`() {
        val state = ActionState()
        assertThat(state.advancePage(3)).isEqualTo(1)
        assertThat(state.advancePage(3)).isEqualTo(2)
        assertThat(state.advancePage(3)).isEqualTo(0) // 순환
    }

    @Test
    fun `totalCount가 0이면 0을 반환한다`() {
        val state = ActionState()
        assertThat(state.advancePage(0)).isEqualTo(0)
    }

    @Test
    fun `resetForContextChange는 모든 상태를 초기화한다`() {
        val state = ActionState()
        state.advancePage(5)
        state.updateExpanded(true)

        state.resetForContextChange()

        assertThat(state.selectedPage).isEqualTo(0)
        assertThat(state.expanded).isFalse()
    }
}
```

우선 순위:
1. **Factory 분기 테스트** — 타입 판정 로직이 가장 버그가 나기 쉬움
2. **State 경계값 테스트** — advancePage의 순환, 0/음수 입력
3. **엣지 케이스** — null 입력, 빈 리스트, 극단값

### 11.3 State 스냅샷 저장/복원

현재 State는 메모리에만 존재하므로, 프로세스 재생성 시 초기화된다.

```kotlin
// 확장: SavedStateHandle 연동
@Stable
class ActionState(
    private val savedStateHandle: SavedStateHandle? = null
) {
    var selectedPage by mutableIntStateOf(
        savedStateHandle?.get<Int>("selectedPage") ?: 0
    )
        private set

    fun advancePage(totalCount: Int): Int {
        // ... 기존 로직
        savedStateHandle?.set("selectedPage", selectedPage)
        return selectedPage
    }
}
```

판단 기준:
- **필요한 경우**: 사용자가 페이지 3/5를 보고 있다가 백그라운드 → 프로세스 재생성 → 1/5로 돌아가면 안 될 때
- **불필요한 경우**: 탭 전환이나 스크롤로 ViewHolder가 재활용될 때 어차피 resetForContextChange()가 호출되므로, 대부분의 리스트 UI에서는 불필요

### 11.4 Contract 변경 시 하위 호환 전략

공통 Contract에 프로퍼티를 추가할 때, 기존 도메인 Factory가 깨지지 않도록 해야 한다.

```kotlin
// 안전한 추가: default 값 제공
@Immutable
data class ActionRefreshData(
    override val imagePosition: ImagePosition = ImagePosition.LEFT,
    override val uts: UTSTrackingDataV2?,
    override val colorCode: String?,
    val textBtn: String? = null,
    val isRefreshLabel: Boolean = true,
    val totalPageCount: Int = 1,
    val showBadge: Boolean = false,  // 새 프로퍼티: default false → 기존 Factory 수정 불필요
) : ActionData
```

규칙:
- data class에 프로퍼티 추가 시 **반드시 default 값**을 제공
- interface에 프로퍼티 추가 시 **반드시 default getter**를 제공
- sealed class에 새 서브타입 추가 시, Router의 `when` 분기에 누락되면 **컴파일 에러**로 잡힘 (sealed의 장점)

### 11.5 성능 측정 기준

"이 패턴이 성능에 영향을 주는가?"를 판단할 때의 기준:

측정 대상:
- Factory.from() 호출 시간: 보통 0.1ms 이하이므로 병목이 되지 않음
- Composable recomposition 범위: State 변경 시 해당 타입의 하위 Composable만 recompose되는지 확인
- ViewHolder 재활용 시 State 초기화 비용: resetForContextChange()의 호출 빈도

확인 방법:
- Layout Inspector로 recomposition count 확인
- Systrace로 Factory 호출 구간 측정
- 문제가 **측정 지표로 명확히 확인**되기 전까지 최적화하지 않음

### 11.6 마이그레이션 가이드

기존 interface 패턴에서 data class 패턴으로 전환할 때의 체크리스트:

1. benchmarkable의 interface 프로퍼티 목록 확인
2. 모든 도메인 구현체에서 override하는 프로퍼티가 동일한지 확인
3. 동일하다면:
    - interface → sealed interface + data class로 변환
    - 도메인 구현체 → object Factory로 변환
    - 구현체의 override 로직을 Factory.from() 안으로 이동
4. Router/Composable에서 `is DomainImpl` 분기 → `is DataClass` 분기로 변경
5. 삭제된 파일 목록 확인 (도메인 구현체, 중복 Composable/State/Params)
6. 컴파일 → 테스트 → 동작 확인

---

## 12) Skill 저장용 핵심 블록

```text
[목표]
도메인에 종속되지 않는 UI 공통화 구조를 유지한다.

[원칙]
- Contract-First
- Domain->Contract 변환 단일화(from/factory)
- Params/State 분리
- Intent로 이벤트 전달, side-effect는 상위 처리

[구현 형태]
- 조합형(Composite Contract): 여러 하위 컴포넌트 조합
- 타입분기형(Polymorphic Contract): sealed 타입 + Router 분기

[룰]
1) UI 공통 모듈에서 도메인 타입 참조 금지
2) Renderer는 표현만 담당
3) A11y/빈값/간격 정책 공통화
```

---

## 13) 현재 코드베이스 매핑 (프로젝트별 참고)

> 이 섹션은 프로젝트마다 해당 경로로 수정하여 사용한다.

- ItemCard:
    - `benchmarkable/.../common/itemcard`
    - `.../home/content/section/itemCard`

- CardInfo:
    - `benchmarkable/.../common/itemcard/cardInfo`
    - `.../home/content/section/itemCard/cardInfo`

- BottomAction (Action 영역만):
    - `benchmarkable/.../common/bottomAction`
    - `.../home/content/section/composable/common/bottomAction`
    - 제외: `.../bottomAction/coupon`, `.../bottomAction/landing`
