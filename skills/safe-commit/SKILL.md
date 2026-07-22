---
name: 커밋
description: 코드 변경 사항을 셀프 리뷰 후 안전하게 커밋한다. 작업별 분리 커밋, develop/master 브랜치 보호, 한국어 커밋 메시지 형식("타입: 설명")을 지킬 때 사용한다.
---

# Safe Commit 스킬

> **규칙 SSOT**: 프로젝트에 `docs/GIT_CONVENTION.md`가 있으면 해당 문서를 따른다.
> 없으면 이 스킬과 현재 Codex Git 지침의 더 엄격한 규칙을 따른다.

커밋 요청 시 아래 절차를 **반드시 순서대로** 수행한다.

---

## 1. 브랜치 확인

```bash
git branch --show-current
```

- `develop` 또는 `master`이면 직접 커밋하지 않는다.
- 기능 브랜치가 없으면 `codex/` prefix로 새 브랜치를 만든 뒤 작업한다.
- 사용자가 다른 prefix를 명시한 경우만 그 지시를 따른다.
- 브랜치 생성/전환 후에는 현재 브랜치를 다시 확인한다.

---

## 2. 변경 사항 확인 + 분리 계획

```bash
git status
git diff --stat
git diff --check
```

- 변경 파일을 **목적별로 그룹핑**한다
- 서로 다른 목적(기능/버그수정/문서/Lint 등)은 **별도 커밋으로 분리**
- 사용자가 만들었거나 작업 범위와 무관한 변경은 되돌리지 않는다
- untracked 파일은 출처와 목적을 확인한 뒤 필요한 경우에만 포함한다

---

## 3. 셀프 리뷰

변경된 **모든 파일**을 다시 읽고 검토:

- 불필요한 코드 (디버깅 로그, 주석 처리된 코드)
- 잘못된 로직 (조건 분기 오류, off-by-one)
- thread-safety 이슈 (불필요한 `withContext`, race condition)
- import 누락/미사용
- 기존 코드 스타일과의 불일치
- Android 변경이면 가능한 범위의 Gradle compile/test를 실행
- 검증 실패 시 실패 원인이 이번 변경인지 먼저 확인

문제 발견 시 **즉시 수정** 후 `git diff`로 재확인.

---

## 4. 그룹별 커밋

각 그룹에 대해:

```bash
git add [그룹에 해당하는 파일들]
git commit -m "$(cat <<'EOF'
타입: 설명

- 상세 변경 내용
EOF
)"
```

- `git add -A` 사용 금지 → 파일 명시적 지정
- 민감 파일(.env, credentials) 포함 여부 확인
- 커밋 메시지는 한국어 설명을 사용하고 형식은 `타입: 설명`으로 작성한다.
- 기본 타입은 `feat`, `fix`, `refactor`, `docs`, `style`, `chore`를 사용한다.
- 본문은 선택 사항이며 변경 이유를 짧게 남길 때만 작성한다.
- Co-Authored-By는 프로젝트/사용자가 명시한 경우에만 추가한다.

---

## 5. 푸시

- 사용자가 "푸시" 또는 "커밋푸시"를 요청한 경우에만 수행
- 원격 추적 없는 브랜치: `git push -u origin {브랜치명}`
- 푸시 전 `git status --short --branch`로 working tree와 upstream 상태를 확인한다.

---

## 6. 완료 보고

커밋 결과를 사용자에게 보고:
- 브랜치명
- 커밋 목록 (해시 + 제목)
- 총 변경 파일 수
