# Codex Skills

이 디렉터리는 현재 로컬 Codex 환경의 스킬을 다른 컴퓨터와 공유하기 위한 스냅샷이다.

## 구조

| 경로 | 의미 | setup.sh 배포 |
|------|------|---------------|
| `local/` | 로컬 `~/.codex/skills`에 설치된 사용자/추가 스킬 | 예 |
| `system/` | Codex 기본 시스템 스킬 참고용 백업 | 아니오 |

`setup.sh`는 `local/*`만 `~/.codex/skills/`로 배포한다.
`system/*`는 Codex가 기본 제공하는 스킬이므로 새 환경에서 누락 확인이나 참고가 필요할 때만 사용한다.

## 동기화 기준

- 스킬 본문 `SKILL.md`
- 스킬이 참조하는 `references/`
- 실행 보조용 `scripts/`
- 아이콘/샘플 등 `assets/`
- 라이선스 파일

`.DS_Store` 같은 로컬 OS 파일은 제외한다.
