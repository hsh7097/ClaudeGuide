---
name: MVI
description: Gmarket Android SRP 화면의 MVI 개발 방향을 검토한다. SrpViewModel, ContentViewModel, intent, receiver, ViewHolder 연결, Selecti 모듈 액션 설계, tracking/landing/cart side effect 책임 분리를 리뷰할 때 사용한다.
argument-hint: "[파일/모듈/질문]"
---

# SRP MVI Review

Gmarket Android SRP 모듈의 intent/receiver 구조를 검토할 때 사용한다.

## 우선 읽을 문서

상세 기준은 아래 문서를 읽고 적용한다.

- `/Users/sanha/Documents/Android/ClaudeGuide/guides/srp-mvi-development.md`

## 검토 순서

1. 변경 대상이 UI-only인지, API/action/tracking 연결 단계인지 먼저 구분한다.
2. `ContentViewModel` 패턴과 `SrpViewModel` 패턴 중 어느 쪽이 더 가까운지 판단한다.
3. `MVIIntentReceiver`, `MVIIntentSender`, `SubIntent`, `reduceForAggregateIntent` 중 어떤 라우팅을 쓰는지 먼저 확인한다.
4. SRP 개별 모듈이면 기본적으로 `SrpViewModel` 내부 모듈별 receiver + `SearchResultFragment` 주입 방식을 우선 검토한다.
5. `TrackingComposeViewHolder`에서는 액션용 `receiver`와 tracking용 `aTrackingIntentSender`가 분리되어 있는지 확인한다.
6. ViewHolder/Composable은 UI 렌더링과 intent 생성만 담당하는지 확인한다.
7. receiver/ViewModel은 navigation, API, cart, login, UTS/ATS/ATracking 같은 side effect를 담당하는지 확인한다.
8. UI state 변경이 있으면 receiver의 `state.data` 변경이 실제 Compose/RecyclerView 갱신 경로와 연결되는지 확인한다.
9. Selecti 모듈은 UI 단독 단계와 API 연결 단계를 분리해서 평가한다.

## 답변 기준

- 사용자가 학습 목적으로 질문하면 정답을 바로 설계해주기보다, 기존 코드 패턴과 비교해서 판단 근거를 알려준다.
- 사용자가 작성한 구조를 검증해달라고 하면 문제점, 적절한 점, 다음 확인 지점을 분리해서 말한다.
- 구현 요청이 아니면 코드를 직접 수정하지 않고 검토 관점 위주로 답한다.
- 구현 요청이면 기존 SRP MVI 패턴을 우선 적용하고, 새 추상화는 최소화한다.

## 빠른 체크리스트

- intent 이름이 사용자 의도를 표현하는가?
- `state`, `view`, `link`, tracking data 등 reducer에 필요한 값만 전달하는가?
- `sendIntent` 이후 side effect는 receiver/ViewModel에서 처리되는가?
- `sendIntent`가 실제로 기대한 receiver로 가는가? (`receiver == null`이면 조용히 무시됨)
- SRP 개별 모듈 액션을 `reduceForAggregateIntent`에 넣지 않고 모듈 전용 receiver로 명시했는가?
- `SubIntent`는 공통/aggregate 라우팅이 필요할 때만 사용했는가?
- `subReceivers`의 타입 매칭이 겹치지 않는가? 겹치면 첫 번째 매칭만 처리된다.
- `TrackingComposeViewHolder`에서 모듈 액션 receiver와 ATracking/ATS sender를 혼동하지 않았는가?
- 단순 클릭/랜딩만 있는 receiver에 불필요한 별도 interface/class를 만들지 않았는가?
- `state.data`를 바꾸는 경우 UI 갱신 경로가 보장되는가?
- `SearchListManager`, `SrpListItem`, `SearchResultFragment` 연결이 빠지지 않았는가?
- UTS/ATS/ATracking이 누락되거나 중복되지 않는가?
- mock/hardcoded UI 데이터가 production path에 남지 않았는가?
- `!!`, main-thread blocking, 임의 라이브러리 추가, 불필요한 build.gradle 변경이 없는가?
