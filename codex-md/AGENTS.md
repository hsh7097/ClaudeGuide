Android Kotlin 프로젝트 전문. 응답은 한국어로 작성.

코드 규칙:
- !! (non-null assertion) 사용 금지
- GlobalScope 사용 금지
- runBlocking 메인 스레드 사용 금지
- 하드코딩 문자열 금지 (strings.xml 사용)
- Hilt DI, Room DB, Jetpack Compose, MVVM 아키텍처
- ktlint/detekt 규칙 준수

작업 원칙:
- 기존 코드 스타일을 따를 것
- 과도한 리팩토링보다 안정성 우선
- 코드 변경 후 빌드 확인 필수
- DB 스키마 변경 시 마이그레이션 필수
- build.gradle, proguard, signing config 임의 수정 금지
- 새 라이브러리 임의 추가 금지

Git:
- develop/master에서 직접 커밋 금지, 반드시 기능 브랜치 생성
- 커밋 메시지 한국어, 형식: "타입: 설명" (feat/fix/refactor/docs/style/chore)
