#!/bin/bash
# Hook 1: 위험 키워드 감지 → 경량 리뷰 자동 포함
# Event: PostToolUse (Edit|Write)
# 트리거: Activity, State, Navigation, Async, Cache, Lifecycle 등 핵심 키워드
#
# 동작: 키워드 감지 시 systemMessage로 회귀 리스크 점검 요청
# 성능: jq + grep만 사용 (< 50ms)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# 파일 경로 + 변경 내용 추출
if [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
else
  exit 0
fi

[ -z "$CONTENT" ] && exit 0

# .md, .json, .xml 등 비코드 파일은 스킵
case "$FILE_PATH" in
  *.md|*.json|*.xml|*.txt|*.conf|*.properties|*.gradle|*.toml)
    exit 0
    ;;
esac

# import/package 줄 제외한 실제 코드만 분석
CODE=$(echo "$CONTENT" | grep -v "^import " | grep -v "^package ")

# 위험 키워드 패턴 (Android/아키텍처 핵심)
RISKY_PATTERNS="onSaveInstanceState|onRestoreInstanceState|registerForActivityResult|ActivityResultLauncher|NavHost|NavGraph|NavController|navigate\(|LaunchedEffect|DisposableEffect|rememberSaveable|GlobalScope|runBlocking|synchronized|@Volatile|MutableSharedFlow|StateFlow\.value|Channel<|addMigration|MIGRATION|RememberCoroutineScope|viewModelScope\.launch|lifecycleScope"

if echo "$CODE" | grep -qE "$RISKY_PATTERNS"; then
  MATCHED=$(echo "$CODE" | grep -oE "$RISKY_PATTERNS" | sort -u | head -3 | tr '\n' ', ' | sed 's/,$//')
  cat <<EOJSON
{"systemMessage":"[Hook:위험키워드] ${MATCHED} 감지. 이 변경의 (1) 회귀 리스크 2개 (2) 상태 꼬임 가능성을 한 줄씩 언급해주세요."}
EOJSON
fi

exit 0
