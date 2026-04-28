# ClaudeGuide

Claude Code와 Codex에서 사용하는 스킬, 가이드, CLAUDE.md 파일을 중앙 관리하는 저장소.

## Quick Start

```bash
# 1. 클론
git clone https://github.com/hsh7097/ClaudeGuide.git ~/Documents/Android/ClaudeGuide

# 2. 심볼릭 링크 설정
cd ~/Documents/Android/ClaudeGuide
./setup.sh

# 3. (선택) 프로젝트 스킬 링크
mkdir -p ~/Documents/Android/Gmarket/.claude/skills
ln -sf ~/Documents/Android/ClaudeGuide/skills/ui-commonization \
       ~/Documents/Android/Gmarket/.claude/skills/ui-commonization
```

## 파일 구조

```
ClaudeGuide/
├── guides/                # ~/.claude/guides/ 에 심볼릭 링크
│   ├── ui-domain-commonization.md   # UI-도메인 공통화 가이드 (요약)
│   ├── bi-writing.md                # BI 기술 공유 문서 작성 가이드
│   └── yearly-review.md             # 연말평가 작성 가이드
├── skills/                # ~/.claude/skills/ 및 프로젝트 .claude/skills/ 에 배포
│   ├── dev-mode/
│   ├── review-mode/
│   └── ui-commonization/
├── codex-skills/          # ~/.codex/skills/ 공유용 스냅샷
│   ├── local/             # setup.sh가 ~/.codex/skills/ 로 배포
│   └── system/            # Codex 기본 시스템 스킬 참고용 스냅샷
├── codex-plugin-skills/   # Codex plugin cache 스킬 참고용 스냅샷
├── claude-md/             # CLAUDE.md 백업/참조
│   ├── gmarket-global-CLAUDE.md
│   └── gmarket-project-CLAUDE.md
├── docs/                  # 상세 참고 문서
│   └── ui-domain-commonization-guide.md  # 공통화 가이드 전체 (실제 코드 포함)
├── setup.sh               # 환경 설정 스크립트
├── CLAUDE.md              # Claude Code용 프로젝트 설명
└── README.md              # 이 파일
```

## 가이드 목록

| 파일 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `guides/ui-domain-commonization.md` | `공통화`, `Contract`, `Factory 패턴` | UI-도메인 공통화 작업 가이드 |
| `guides/bi-writing.md` | `BI`, `BI 작성`, `기술 공유 문서` | BI 기술 공유 문서 작성 |
| `guides/yearly-review.md` | `평가`, `연말평가`, `본인평가` | 연말평가 본인평가 작성 |

## 스킬 목록

### Claude 전역 스킬

| 스킬 | 트리거 | 설명 |
|------|--------|------|
| `skills/dev-mode/SKILL.md` | `개발` | 최소 변경 + 자기 검수 기반 개발 모드 |
| `skills/plan-mode/SKILL.md` | `계획` | 구현 전 설계/합의 강제 모드 |
| `skills/review-mode/SKILL.md` | `리뷰` | 변경 코드 시니어 관점 검수 |
| `skills/safe-commit/SKILL.md` | `커밋`, `푸시` | 브랜치/변경 범위 확인 후 안전 커밋 |
| `skills/docs-sync/SKILL.md` | `문서` | 작업 전후 문서 맥락 동기화 |
| `skills/session-reset/SKILL.md` | `정리` | 긴 대화 맥락 정리 |
| `skills/recursive-review/SKILL.md` | `재귀` | 3라운드 실행/검증/수정 사이클 |
| `skills/ui-commonization/SKILL.md` | `공통화` | UI-도메인 공통화 패턴 조회/적용 |
| `skills/bi-writing/SKILL.md` | `BI`, `기술 공유 문서` | BI-Weekly 기술 공유 문서 작성 |

### Codex 스킬 스냅샷

| 경로 | 용도 |
|------|------|
| `codex-skills/local/` | 로컬 `~/.codex/skills` 스킬. `setup.sh` 실행 시 `~/.codex/skills/`로 배포 |
| `codex-skills/system/` | Codex 기본 시스템 스킬 참고용 백업. 기본 배포 대상 아님 |
| `codex-plugin-skills/` | Codex plugin cache 스킬 참고용 백업. plugin 설치로 관리되는 영역이므로 기본 배포 대상 아님 |

## 워크플로우

```
[가이드/스킬 수정]
    ↓
ClaudeGuide/ 에서 수정
    ↓
git commit & push
    ↓
[다른 PC에서]
cd ~/Documents/Android/ClaudeGuide && git pull
    ↓
심볼릭 링크로 자동 반영
```

## 다른 컴퓨터 적용 범위

`./setup.sh`는 아래를 설정한다.

- `guides/*.md` → `~/.claude/guides/`
- `claude-md/gmarket-global-CLAUDE.md` → `~/.claude/CLAUDE.md`
- `skills/*` 전체 파일 → `~/.claude/skills/`
- `codex-skills/local/*` 전체 파일 → `~/.codex/skills/`
- `projects.conf`에 등록된 프로젝트 → `{project}/.claude/skills/`

스킬 디렉터리 내부의 `references/`, `scripts/`, `assets/`도 함께 배포된다.

## 심볼릭 링크 제거

```bash
./setup.sh --unlink
```
