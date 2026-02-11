# ClaudeGuide

Claude Code에서 사용하는 스킬, 가이드, CLAUDE.md 파일을 중앙 관리하는 저장소.

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
├── skills/                # 프로젝트 .claude/skills/ 에 심볼릭 링크
│   └── ui-commonization/
│       └── SKILL.md       # /공통화 슬래시 커맨드 스킬
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

| 스킬 | 슬래시 커맨드 | 설명 |
|------|-------------|------|
| `skills/ui-commonization/SKILL.md` | `/공통화` | UI-도메인 공통화 패턴 조회/적용 |

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

## 심볼릭 링크 제거

```bash
./setup.sh --unlink
```
