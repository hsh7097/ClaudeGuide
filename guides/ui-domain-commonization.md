# UI-도메인 공통화 가이드

## 1. 이 가이드의 목적

도메인 비즈니스 로직의 변경이 UI 컴포넌트의 파손으로 이어지지 않도록 격리한다.
UI 공통 모듈은 "그려지는 법"에만 집중하고, 도메인은 "무엇을 보여줄지"만 결정한다.

---

## 2. 핵심 아키텍처

```text
[Domain Raw Model]
      |
      v
[Factory/Mapper.from(...)]   // 도메인 모듈
      |
      v
[UI Contract Model]          // 공통 UI 모듈
      |
      v
[Renderer(View/Compose)]     // 공통 UI 모듈
      |
      v
[Intent -> Upper Layer Side Effect]
```

---

## 3. 역할 정의

### Contract (공통 UI 모듈에서 정의)
- UI 렌더링에 필요한 최소 속성과 정책 API(`isNullOrEmpty`, `createDescriptionText`)를 정의
- **허용**: 빈값 체크, 접근성 텍스트 생성, 표현을 위한 최소 포맷
- **금지**: 도메인 모델 참조, 가격/쿠폰/재고 같은 도메인 규칙 계산, 네트워크/로그/AB 분기

### Factory/Mapper (도메인 모듈에서 구현)
- 도메인 모델을 Contract로 번역, 비즈니스 규칙을 **값으로 확정**
- **허용**: 타입 판정, 조건부 생성, 데이터 정책(maxLines 등) 결정
- **금지**: UI 위젯 제어, Compose/View API 호출, State 보관, UI 간격/스타일 결정

### Renderer (공통 UI 모듈에서 구현)
- Contract를 화면으로 표현(노출/레이아웃/스타일)
- **허용**: 간격/스타일/애니메이션 처리, Intent 발행
- **금지**: 도메인 필드 직접 해석(`if (data.type == "SOLD_OUT")`), side-effect 실행

### Intent
- 사용자 액션 결과를 순수 이벤트 모델로 상위 레이어에 전달
- **금지**: 자체적으로 상태 확정, 비즈니스 처리 실행

### State
- UI 변화값 보관(`selectedPage`, `expanded` 등)
- **금지**: 불변 입력값 보관, 도메인 원본 보관

### Params
- 화면 컨텍스트의 불변 입력값 전달(`selectedTabIndex`, `itemMaxCount` 등)
- **금지**: 사용자 상호작용에 따라 내부 값 변경 (그건 State)

---

## 4. 두 가지 구현 패턴

### 4.1 조합형(Composite Contract)

**적용**: 한 UI 블록이 여러 하위 블록을 **동시에** 합성할 때

구조:
```kotlin
// 합 Contract — 하위 컴포넌트를 optional 프로퍼티로 조합
interface CompositeData {
    val sectionA: SectionAData?  // 하위 Contract
    val sectionB: SectionBData?
    fun isNullOrEmpty(): Boolean
    fun createDescriptionText(): String  // 접근성: 하위 설명 취합
}

// 도메인 Factory — 하위 Factory를 각각 호출하여 조립
data class DomainCompositeData(...) : CompositeData {
    companion object {
        fun from(model: DomainModel) = DomainCompositeData(
            sectionA = DomainSectionAData.from(model),
            sectionB = DomainSectionBData.from(model),
        )
    }
}

// Renderer — Column으로 하위 Composable 합성 + Custom Content Slot
@Composable
fun CompositeCompose(data: CompositeData) {
    Column {
        data.sectionA?.let { SectionACompose(it) }
        data.sectionB?.let { SectionBCompose(it) }
    }
}
```

특징:
- 하위 컴포넌트가 **공존** (모두 렌더링)
- State/Intent 없음 (stateless)
- Custom Content Slot으로 도메인별 커스텀 가능
- 합 Composable이 하위 간격을 중앙 관리

### 4.2 타입분기형(Polymorphic Contract)

**적용**: 같은 자리에서 타입별로 **하나만** 다른 UI를 렌더링할 때

구조:
```kotlin
// Contract — sealed interface + data class 서브타입
sealed interface ActionData {
    data class Landing(val url: String?) : ActionData
    data class Refresh(val totalPageCount: Int) : ActionData
    data class Expand(...) : ActionData
}

// State — UI 변화값 보관
@Stable
class ActionState {
    var selectedPage by mutableIntStateOf(0)
    fun advancePage(totalCount: Int): Int { ... }
    fun resetForContextChange() { ... }
}

// Intent — 이벤트 전달
sealed interface ActionIntent {
    data class RefreshPage(val totalCount: Int) : ActionIntent
    data class SetExpanded(val expanded: Boolean) : ActionIntent
}

// 도메인 Factory — 타입 판정 + data class 생성
object DomainActionFactory {
    fun from(model: DomainModel, params: ActionParams): ActionData? {
        return when {
            params.isRefresh -> ActionData.Refresh(...)
            model.hasLanding -> ActionData.Landing(...)
            else -> ActionData.Expand(...)
        }
    }
}

// Router Composable — sealed type 분기
@Composable
fun ActionRouter(data: ActionData, state: ActionState, onAction: (ActionIntent) -> Unit) {
    when (data) {
        is ActionData.Landing -> LandingCompose(data, onAction)  // private
        is ActionData.Refresh -> RefreshCompose(data, state, onAction)  // private
        is ActionData.Expand -> ExpandCompose(data, state, onAction)  // private
    }
}
```

특징:
- 하위 컴포넌트 중 **하나만 선택** (배타적)
- State + Intent 있음
- 타입 분기 지점은 **Factory + Router 2곳으로 제한**
- Router만 public, 하위 Composable은 private

### 4.3 패턴 선택 기준

| 조건 | 패턴 |
|------|------|
| 하위 컴포넌트가 동시에 보여야 함 | 조합형 |
| 하위 컴포넌트 중 하나만 선택됨 | 타입분기형 |
| 사용자 인터랙션이 없음 | 조합형 (stateless) |
| 사용자 인터랙션이 있음 | 타입분기형 (State + Intent) |

두 패턴은 **중첩 가능** — 조합형의 하위 컴포넌트가 타입분기형일 수 있다.

---

## 5. data class vs interface 판단 기준

기본 원칙: **data class를 기본으로 채택**한다.

```text
Q: Contract 프로퍼티가 모든 도메인에서 동일한가?
|
+-- YES --> data class (Factory에서 값만 주입)
|
+-- NO  --> Q: 도메인별 레이아웃 정책이나 표현 다형성이 필요한가?
            |
            +-- YES --> interface (도메인이 override, 구현체는 data class)
            |
            +-- NO  --> data class (Factory에서 변환 후 주입)
```

핵심:
- "도메인마다 **값**이 다르다" → data class
- "도메인별 **레이아웃 정책이나 표현 다형성**이 필요하다" → interface
- "lazy 계산이 필요하다"는 interface의 이유가 아님 → Factory/State로 이동

---

## 6. 경계 위반 금지 규칙

```kotlin
// ❌ Contract에서 비즈니스 규칙 계산
interface PriceData {
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
if (data.infoLabels?.any { it.type == "SOLD_OUT" } == true) { ... }

// ✅ Renderer는 Contract가 제공한 값만 사용
data.infoLabels?.forEach { InfoLabelCompose(it) }
```

```kotlin
// ❌ Factory에서 UI 간격 결정
fun from(...) = Data(topPadding = 4.dp)

// ✅ Factory는 데이터 정책만 결정
fun from(...) = Data(maxLines = if (scale == LARGE) 1 else 2)
```

---

## 7. State 생명주기

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
- State는 **ViewHolder(또는 `remember`)**에서 생성 — Factory에서 생성하지 않음
- 아이템 key가 변경되면 반드시 `resetForContextChange()` 호출
- Process recreation 시 State 복원은 **기본적으로 불필요**
- Params(불변 입력)과 State(변화값)를 **절대 섞지 않기**

---

## 8. 팀 공통 룰

1. 공통 UI 모듈에서 도메인 모델 import 금지
2. 도메인 → Contract 변환은 `from(...)`/`Factory`로 단일화
3. Renderer에는 비즈니스 분기/데이터 가공 금지
4. Params(입력)와 State(변화값) 분리
5. 클릭 처리 side-effect는 상위 레이어에서만 실행
6. 접근성 설명문 생성 책임은 Contract에 두기
7. View/Compose 정책 동등성 유지(노출/간격/최대라인)
8. 타입 분기는 **Factory + Router 2단으로 제한**
9. Renderer 하위 Composable은 **private** — Router만 public

---

## 9. 코드 리뷰 체크리스트

- [ ] UI 모듈이 도메인 모델을 직접 참조하지 않는가?
- [ ] 변환 로직이 Factory/Mapper 한곳으로 수렴되는가?
- [ ] Renderer가 Contract만 다루는가?
- [ ] Params/State/Intent 역할이 분리되어 있는가?
- [ ] 타입 분기 지점이 Factory/Router로 제한되어 있는가?
- [ ] A11y 문장이 Contract 기반으로 일관 생성되는가?
- [ ] Contract 수정 시 기본값(default)을 제공하여 하위 호환을 유지하는가?
- [ ] State는 ViewHolder에서 관리되고, bind 시 reset되는가?

---

## 10. 안티패턴 → 교정

| 안티패턴 | 교정 |
|----------|------|
| Renderer에서 도메인 필드 직접 참조 | Contract로 변환 후 전달 |
| 클릭 핸들러에서 바로 네트워크/화면이동 실행 | Intent만 전달, 상위에서 side-effect |
| 호출부마다 임시 매핑 반복 | Factory/Mapper 단일 진입점 |
| totalCount + selectedPage + expanded 혼합 | Params/State 분리 |
| 프로퍼티 동일한데 interface 사용 | data class + Factory로 전환 |
| Renderer 내부에서 when(data)로 재분기 | Router에서만 분기, 하위는 private |
| Contract에서 가격 할인율 계산 | Factory에서 계산, Contract는 결과값만 보유 |
| Factory에서 UI 간격(dp) 결정 | 간격은 Renderer 책임, Factory는 데이터 정책만 |

---

## 11. Contract 변경 시 하위 호환

```kotlin
// data class → 반드시 default 값 제공
data class ActionRefreshData(
    val totalPageCount: Int,
    val showBadge: Boolean = false,  // 새 프로퍼티: 기존 Factory 수정 불필요
) : ActionData

// interface → 반드시 default getter 제공
interface InfoLabelsData {
    val showNewFlag: Boolean
        get() = false  // 기존 구현체 깨지지 않음
}

// sealed class → 새 서브타입 추가 시 Router의 when에서 컴파일 에러로 잡힘
```

---

## 12. 테스트 우선순위

1. **Factory 분기 테스트** (필수) — 타입 판정 로직이 가장 버그 나기 쉬움
2. **State 경계값 테스트** (필수) — 순환, 0/음수 입력, reset
3. **Intent + tracking 전달 테스트** — 클릭별 올바른 Intent 발행
4. **A11y 테스트** — description 누락/중복/구분자
5. **Renderer 정책 동등성** — View/Compose 노출/간격/최대라인 일치

---

## 13. 마이그레이션 체크리스트 (interface → data class)

1. 공통 UI 모듈의 interface 프로퍼티 목록 확인
2. 모든 도메인 구현체에서 override하는 프로퍼티가 동일한지 확인
3. 동일하다면:
    - interface → sealed interface + data class로 변환
    - 도메인 구현체 → object Factory로 변환
    - 구현체의 override 로직을 Factory.from() 안으로 이동
4. Router/Composable 분기를 `is DataClass`로 변경
5. 삭제된 파일 목록 확인
6. 컴파일 → 테스트 → 동작 확인

---

## 14. 구현 형태 요약

| 조건 | UI 위치 | Mapper 위치 | Mapper 방식 |
|------|---------|-------------|-------------|
| 단일 도메인 + 상태 있음 | 도메인 내부 | 도메인 내부 | Factory 함수 또는 sealed class |
| 다중 도메인 + 상태 없음 | 공통 UI | 각 도메인 | data class Factory + Interface |
| 다중 도메인 + 상태 있음 | 공통 UI | 각 도메인 | data class Factory + Interface + 도메인별 State |
| 복합 컴포넌트 | 공통 UI | 각 도메인 | data class (from 팩토리) + 하위 sealed class |

---

## 참고

- 상세 코드 예시 및 실제 파일 매핑: `docs/ui-domain-commonization-guide.md`
- 이 가이드의 원칙은 `CLAUDE.md`의 Compose 공통 컴포넌트 패턴과 일관된다
