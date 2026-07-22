---
name: 컴포즈 프리뷰
description: Gmarket Android Compose preview를 만들거나 정리할 때 사용한다. "컴포즈 프리뷰", "컴포즈프리뷰", "Compose preview", "프리뷰 만들어줘"처럼 요청하거나 SRP/Home/VIP ViewHolder 내부 Compose, GmarketMobile debug source set preview, PreviewParameterProvider 사용 여부, preview 샘플 데이터 최소화, debug 전용 하드코딩 허용 범위, compileProdDebugKotlin 검증이 필요한 경우에 사용한다.
---

# 컴포즈 프리뷰

> Gmarket Android에서 Compose preview를 production 코드와 분리해 안전하게 추가한다.

## 기본 원칙

- 이 스킬이 호출되지 않는 경우를 대비해 `컴포즈프리뷰`와 `Compose preview` 표현도 같은 의미로 취급한다.
- GmarketMobile 화면/ViewHolder용 preview는 `GmarketMobile/src/debug/java` 아래에 만든다.
- `debugFinal`도 `src/debug`를 바라보는 구조인지 `build.gradle.kts`의 `sourceSets`로 확인한다.
- production `main` 코드에는 preview용 데이터, `@Preview`, `PreviewParameterProvider`, sample 문자열을 넣지 않는다.
- preview는 대상 composable의 배치와 상태 확인용이다. 하위 공통 컴포넌트의 모든 edge case를 다시 만들지 않는다.
- debug source set 내부 sample 문자열과 sample URL은 허용한다. production UI 문자열을 추가/변경하는 작업이 아니면 `strings.xml`을 건드리지 않는다.
- 새 라이브러리, build.gradle, proguard, signing 설정은 preview 때문에 수정하지 않는다.

## 작업 순서

1. 대상 composable과 module을 확인한다.
   - 예: `ItemCardSelectiContainer`는 `GmarketMobile/src/main/java/.../selectiContainer`.
   - `rg --files | rg 'Preview|preview'`로 같은 module의 preview 위치와 스타일을 본다.

2. preview 파일 위치를 정한다.
   - GmarketMobile SRP preview 예:
     `GmarketMobile/src/debug/java/com/ebay/kr/gmarket/main/domain/search/result/viewholders/preview/FooPreview.kt`
   - provider가 꼭 필요하면:
     `GmarketMobile/src/debug/java/com/ebay/kr/gmarket/main/domain/search/result/viewholders/preview/provider/FooPreviewProvider.kt`

3. 기존 preview 패턴을 따른다.
   - 단일 상태면 `@Preview` 함수 안에서 data를 직접 생성한다.
   - 상태가 2개 이상이고 비교 가치가 있으면 `PreviewParameterProvider`를 분리한다.
   - PR 4184의 `SimpleContentListBannerPreview.kt`처럼 단순 preview는 provider 없이 작성한다.

4. preview 데이터는 최소화한다.
   - composable의 책임을 보여주는 필드만 넣는다.
   - child component가 이미 preview를 가지고 있으면 child의 상세 케이스를 복제하지 않는다.
   - 같은 item card가 여러 개 필요한 row/carousel이면 단일 sample item을 반복한다.
   - 실제 API 전체 JSON을 그대로 옮기지 않는다.
   - `ImmutableList`가 필요한 모델은 `persistentListOf`를 사용한다.

5. callback은 UI 확인에 필요한 정도만 둔다.
   - pure composable이면 ViewHolder/Fragment/receiver를 만들지 말고 composable을 직접 호출한다.
   - click callback은 기본값이 있으면 생략하고, 필요하면 `{}`로 비운다.

6. preview에서 앱 전역 context 의존을 피한다.
   - `PriceWithCouponInfo`처럼 `BaseApplication.get()` 접근성 문자열 경로를 타는 인터페이스는 preview 샘플에서 `discountTextChar`, `originPriceChar`, `priceTextChar`, `discountRateChar`, `itemPriceChar`, `subPriceInfoChar`를 `null`로 override하는 기존 패턴을 따른다.
   - 리뷰/접근성 description처럼 앱 리소스 접근이 강한 데이터는 화면 검증에 꼭 필요할 때만 넣는다.

7. 검증한다.
   - GmarketMobile preview:
     `./gradlew :GmarketMobile:compileProdDebugKotlin --console=plain`
   - feature module preview:
     `./gradlew :feature:compileProdDebugKotlin --console=plain`
   - 기존 deprecation/resource warning은 구분해서 보고하고, 새 preview 파일로 인한 compile error만 수정한다.

8. 마무리 확인을 한다.
   - `git status --short`로 변경 파일이 debug preview 파일 중심인지 확인한다.
   - `git diff --stat` 또는 신규 파일 내용 확인으로 production 코드 변경이 섞이지 않았는지 본다.

## 코드 형태

단순 preview는 아래 형태를 우선한다.

```kotlin
@Preview(widthDp = 411, showBackground = true, backgroundColor = 0xFFFFFFFF)
@Composable
fun FooPreview() {
    FooComposable(
        data = previewFooData(),
        onClick = {}
    )
}

private fun previewFooData() = FooData(
    title = "샘플",
    items = persistentListOf(
        previewFooItem(),
        previewFooItem(),
        previewFooItem()
    )
)
```

## 판단 기준

- `PreviewParameterProvider`를 쓰는 경우: 여러 상태를 한 화면에서 반복 확인해야 할 때.
- direct data를 쓰는 경우: 단일 대표 상태만 있으면 충분할 때.
- sample image URL을 쓰는 경우: 레이아웃 비율, crop, row 높이 확인에 이미지가 중요할 때.
- sample image URL을 줄이는 경우: 대상이 container 배치이고 item card 자체는 이미 별도 preview가 있을 때.
- footer/header/row 배치가 목적이면 item card 데이터는 하나만 만들고 반복한다.
