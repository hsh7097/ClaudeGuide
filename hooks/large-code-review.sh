#!/bin/bash
# Hook 3: 코드 80줄 이상 생성 시 → 경량 리뷰 자동 포함
# Event: PostToolUse (Edit|Write)
# 트리거: 새로 작성/변경된 코드가 80줄 이상
#
# 동작: systemMessage로 책임 분리 + 테스트 포인트 요청
# 성능: jq + wc만 사용 (< 50ms)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# 변경된 코드 추출
if [ "$TOOL_NAME" = "Write" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
elif [ "$TOOL_NAME" = "Edit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
  exit 0
fi

[ -z "$CONTENT" ] && exit 0

# .md, .json 등 비코드 파일은 스킵
case "$FILE_PATH" in
  *.md|*.json|*.xml|*.txt|*.conf|*.properties)
    exit 0
    ;;
esac

# 줄 수 카운트
LINE_COUNT=$(echo "$CONTENT" | wc -l | tr -d ' ')

if [ "$LINE_COUNT" -ge 80 ]; then
  cat <<EOJSON
{"systemMessage":"[Hook:대규모코드] ${LINE_COUNT}줄 코드 생성/변경. (1) 책임 분리 위반 여부 (2) 확장 가능성 (3) 테스트 포인트 1개를 간단히 언급해주세요."}
EOJSON
fi

exit 0
