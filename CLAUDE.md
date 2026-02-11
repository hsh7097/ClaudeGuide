# ClaudeGuide

이 프로젝트는 Claude Code에서 사용하는 스킬, 가이드, CLAUDE.md 파일을 중앙 관리하는 저장소다.

## 목적

- 여러 환경(회사/집 PC)에서 동일한 Claude 설정을 유지
- 스킬/가이드의 버전 관리 및 변경 이력 추적
- `git pull` + `./setup.sh`로 빠른 환경 동기화

## 구조

```
ClaudeGuide/
├── CLAUDE.md              # 이 파일 (프로젝트 메타)
├── README.md              # 사용법 안내
├── setup.sh               # 환경 설정 스크립트 (심볼릭 링크)
├── guides/                # ~/.claude/guides/ 에 링크될 가이드 파일
│   ├── ui-domain-commonization.md
│   ├── bi-writing.md
│   └── yearly-review.md
├── skills/                # 프로젝트 .claude/skills/ 에 링크될 스킬
│   └── ui-commonization/
│       └── SKILL.md
├── claude-md/             # 프로젝트별 CLAUDE.md 백업/참조
│   ├── gmarket-global-CLAUDE.md    # ~/.claude/CLAUDE.md
│   └── gmarket-project-CLAUDE.md   # Gmarket/CLAUDE.md
└── docs/                  # 상세 참고 문서
    └── ui-domain-commonization-guide.md
```

## 사용법

### 새 환경 설정
```bash
git clone https://github.com/hsh7097/ClaudeGuide.git ~/Documents/Android/ClaudeGuide
cd ~/Documents/Android/ClaudeGuide
./setup.sh
```

### 수정 후 동기화
```bash
cd ~/Documents/Android/ClaudeGuide
# 파일 수정 후
git add . && git commit -m "가이드 업데이트" && git push
```

### 다른 PC에서 동기화
```bash
cd ~/Documents/Android/ClaudeGuide
git pull
```

## 파일 수정 시 주의

- `guides/` 파일 수정 → 심볼릭 링크를 통해 `~/.claude/guides/`에 자동 반영
- `skills/` 파일 수정 → 심볼릭 링크가 설정된 프로젝트에 자동 반영
- `claude-md/` 파일 수정 → 참조용이므로 실제 CLAUDE.md에는 수동 복사 필요
- `docs/` 파일 수정 → 참조용, 프로젝트 docs/에는 수동 복사 필요

## Claude 작업 지침

### 가이드/스킬 관련 작업 시 필수 절차

**작업 전**: 반드시 이 ClaudeGuide 저장소를 최신 상태로 갱신한 후 작업을 시작한다.
```bash
cd ~/Documents/Android/ClaudeGuide && git pull
```

**작업 후**: 가이드/스킬/문서 파일을 수정했다면, 작업 완료 시 자동으로 커밋 & push 한다.
```bash
cd ~/Documents/Android/ClaudeGuide
git add -A
git commit -m "가이드 업데이트: [변경 요약]"
git push
```

### 자동 커밋/push 규칙

Claude가 이 저장소의 파일(`guides/`, `skills/`, `docs/`, `claude-md/`)을 **수정하거나 새로 생성**한 경우:
1. 작업이 완료되면 변경된 파일을 `git add`
2. 변경 내용을 요약한 커밋 메시지로 `git commit`
3. `git push`로 원격에 반영
4. 사용자에게 push 완료를 알림

심볼릭 링크로 연결된 파일은 `~/.claude/guides/`나 프로젝트 `.claude/skills/`에서 수정해도 이 저장소의 파일이 실제로 변경되므로, 동일하게 커밋 & push 한다.

### 일반 작업 시

이 프로젝트에서 Claude에게 **"읽어서 작업해줘"** 라고 하면:
1. 먼저 `git pull`로 최신 상태 확인
2. 이 CLAUDE.md를 읽어 구조 파악
3. 필요한 가이드/스킬 파일을 Read로 참조
4. 해당 내용을 기반으로 작업 수행
5. 파일 변경이 있었으면 커밋 & push
