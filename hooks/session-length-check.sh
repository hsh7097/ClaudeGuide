#!/bin/bash
# Hook 2: 대화 길어짐 감지 → /정리 제안
# Event: Stop
# 트리거: 대화 25턴 이상
#
# 동작: 세션당 1회만 systemMessage로 /정리 제안
# 상태: /tmp/claude-session-warned-{session_id} 파일로 중복 방지

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

# 이미 이 세션에서 경고했으면 스킵
WARN_FLAG="/tmp/claude-session-warned-${SESSION_ID}"
[ -f "$WARN_FLAG" ] && exit 0

# 턴 수 추정: JSONL에서 "role":"user" 라인 수 = 사용자 턴
TURN_COUNT=$(grep -c '"role":"user"' "$TRANSCRIPT" 2>/dev/null || echo "0")

if [ "$TURN_COUNT" -ge 25 ]; then
  touch "$WARN_FLAG"
  cat <<EOJSON
{"systemMessage":"[Hook:세션정리] 대화가 ${TURN_COUNT}턴 이상 진행되었습니다. 맥락 유실 방지를 위해 /정리 사용을 권장합니다."}
EOJSON
fi

exit 0
