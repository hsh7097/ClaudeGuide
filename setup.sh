#!/bin/bash
# ClaudeGuide Setup Script
# 새 환경(회사/집 PC)에서 한 번만 실행하면 심볼릭 링크가 설정됩니다.
#
# 사용법:
#   chmod +x setup.sh
#   ./setup.sh
#
# 옵션:
#   ./setup.sh --unlink    # 심볼릭 링크 제거

set -e

# ─── 경로 설정 ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
GUIDES_DIR="$CLAUDE_HOME/guides"

# ─── 색상 ───
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ─── 함수 ───
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

create_symlink() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        local existing_source
        existing_source=$(readlink "$target")
        if [ "$existing_source" = "$source" ]; then
            log_info "이미 링크됨: $(basename "$target")"
            return 0
        else
            log_warn "기존 링크 교체: $(basename "$target") ($existing_source -> $source)"
            rm "$target"
        fi
    elif [ -f "$target" ]; then
        log_warn "기존 파일 백업: ${target} -> ${target}.bak"
        mv "$target" "${target}.bak"
    fi

    ln -sf "$source" "$target"
    log_info "링크 생성: $(basename "$target")"
}

remove_symlink() {
    local target="$1"
    if [ -L "$target" ]; then
        rm "$target"
        log_info "링크 제거: $(basename "$target")"
    fi
}

# ─── unlink 모드 ───
if [ "$1" = "--unlink" ]; then
    echo "=== ClaudeGuide 심볼릭 링크 제거 ==="
    echo ""

    # guides 링크 제거
    for guide in "$SCRIPT_DIR"/guides/*.md; do
        [ -f "$guide" ] || continue
        filename=$(basename "$guide")
        remove_symlink "$GUIDES_DIR/$filename"
    done

    echo ""
    log_info "심볼릭 링크 제거 완료"
    exit 0
fi

# ─── 메인 설치 ───
echo "=========================================="
echo "  ClaudeGuide 환경 설정"
echo "=========================================="
echo ""
echo "소스: $SCRIPT_DIR"
echo "대상: $CLAUDE_HOME"
echo ""

# 1. ~/.claude/guides 디렉토리 생성
mkdir -p "$GUIDES_DIR"
log_info "디렉토리 확인: $GUIDES_DIR"

# 2. 가이드 파일 심볼릭 링크
echo ""
echo "--- 가이드 파일 링크 ---"
for guide in "$SCRIPT_DIR"/guides/*.md; do
    [ -f "$guide" ] || continue
    filename=$(basename "$guide")
    create_symlink "$guide" "$GUIDES_DIR/$filename"
done

# 3. 프로젝트 스킬 링크 안내
echo ""
echo "--- 프로젝트 스킬 링크 ---"
echo ""
log_info "프로젝트별 스킬은 해당 프로젝트의 .claude/skills/ 에 수동으로 링크해야 합니다."
echo ""
echo "  예시 (Gmarket 프로젝트):"
echo "    mkdir -p ~/Documents/Android/Gmarket/.claude/skills"
echo "    ln -sf $SCRIPT_DIR/skills/ui-commonization \\"
echo "           ~/Documents/Android/Gmarket/.claude/skills/ui-commonization"
echo ""

# 4. CLAUDE.md 안내
echo "--- CLAUDE.md ---"
echo ""
log_info "CLAUDE.md는 프로젝트마다 다를 수 있으므로 자동 링크하지 않습니다."
echo "  참고용 파일 위치:"
echo "    - 글로벌:  $SCRIPT_DIR/claude-md/gmarket-global-CLAUDE.md"
echo "    - 프로젝트: $SCRIPT_DIR/claude-md/gmarket-project-CLAUDE.md"
echo ""
echo "  필요시 수동 복사:"
echo "    cp $SCRIPT_DIR/claude-md/gmarket-global-CLAUDE.md ~/.claude/CLAUDE.md"
echo ""

# 5. 완료
echo "=========================================="
echo -e "  ${GREEN}설정 완료${NC}"
echo "=========================================="
echo ""
echo "검증:"
echo "  ls -la $GUIDES_DIR/"
echo ""
