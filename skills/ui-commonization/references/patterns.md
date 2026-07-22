# 공통화 패턴 예시

공통화 스킬 본문에서 패턴 선택은 끝났지만, 실제 코드 골격이 필요할 때만 이 문서를 읽는다.

## 조합형

적용: 한 UI 블록이 여러 하위 블록을 동시에 합성할 때.

```kotlin
// 합 Contract: 하위 컴포넌트를 optional 프로퍼티로 조합
interface CompositeData {
    val sectionA: SectionAData? get() = null
    val sectionB: SectionBData? get() = null
    fun isNullOrEmpty(): Boolean
    fun createDescriptionText(): String
}

// 도메인 Factory: 하위 Factory를 각각 호출하여 조립
data class DomainCompositeData(
    override val sectionA: SectionAData?,
    override val sectionB: SectionBData?,
) : CompositeData {
    companion object {
        fun from(model: DomainModel) = DomainCompositeData(
            sectionA = DomainSectionAData.from(model),
            sectionB = DomainSectionBData.from(model),
        )
    }
}

// Renderer: 하위 Composable 합성과 간격 관리를 중앙화
@Composable
fun CompositeCompose(
    data: CompositeData,
    sectionACustom: (@Composable () -> Unit)? = null,
) {
    Column {
        if (sectionACustom != null) {
            sectionACustom()
        } else {
            data.sectionA?.let { SectionACompose(it) }
        }

        if (data.sectionA != null && data.sectionB != null) {
            Spacer(modifier = Modifier.height(4.dp))
        }

        data.sectionB?.let { SectionBCompose(it) }
    }
}
```

체크포인트:

- 하위 블록이 동시에 노출되는가
- 합 Composable이 간격을 중앙 관리하는가
- 각 하위 컴포넌트는 자기 Contract만 읽는가
- side effect는 Intent로 상위에 전달되는가

## 타입분기형

적용: 같은 자리에서 타입별로 하나의 UI만 렌더링할 때.

```kotlin
// Contract: sealed interface + data class 서브타입
sealed interface ActionData {
    data class Landing(val url: String?) : ActionData
    data class Refresh(val totalPageCount: Int) : ActionData
    data class Expand(val expandedText: String) : ActionData
}

// State: 변화값만 보관
@Stable
class ActionState {
    var selectedPage by mutableIntStateOf(0)
        private set

    fun advancePage(totalCount: Int): Int {
        selectedPage = (selectedPage + 1).floorMod(totalCount)
        return selectedPage
    }

    fun resetForContextChange() {
        selectedPage = 0
    }
}

// Intent: 사용자 액션 결과만 표현
sealed interface ActionIntent {
    data class RefreshPage(val totalCount: Int) : ActionIntent
    data class SetExpanded(val expanded: Boolean) : ActionIntent
}

// 도메인 Factory: 타입 판정과 값 확정
object DomainActionFactory {
    fun from(model: DomainModel, params: ActionParams): ActionData? {
        return when {
            params.isRefresh -> ActionData.Refresh(totalPageCount = model.pageCount)
            model.hasLanding -> ActionData.Landing(url = model.landingUrl)
            model.expandText != null -> ActionData.Expand(expandedText = model.expandText)
            else -> null
        }
    }
}

// Router: sealed type 분기. Router만 public, 하위는 private
@Composable
fun ActionRouter(
    data: ActionData,
    state: ActionState,
    onAction: (ActionIntent) -> Unit,
) {
    when (data) {
        is ActionData.Landing -> LandingCompose(data, onAction)
        is ActionData.Refresh -> RefreshCompose(data, state, onAction)
        is ActionData.Expand -> ExpandCompose(data, state, onAction)
    }
}
```

체크포인트:

- 타입 분기는 Factory와 Router 두 지점으로 제한되는가
- State에 불변 Params나 도메인 원본을 보관하지 않는가
- 하위 Composable은 private으로 숨겨져 있는가
- 새 서브타입 추가 시 Router `when`에서 컴파일로 잡히는가
