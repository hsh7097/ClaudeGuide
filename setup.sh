#!/bin/bash
# ClaudeGuide Setup Script
# 새 환경(회사/집 PC)에서 한 번만 실행하면 가이드 파일이 설정됩니다.
#
# macOS/Linux: 심볼릭 링크 생성
# Windows (Git Bash): 파일 복사 (심볼릭 링크에 관리자 권한 필요)
#
# 사용법:
#   chmod +x setup.sh
#   ./setup.sh
#
# 옵션:
#   ./setup.sh --unlink    # 설정 제거

set -e

# ─── 경로 설정 ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
GUIDES_DIR="$CLAUDE_HOME/guides"

# ─── OS 감지 ───
IS_WINDOWS=false
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw"* ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    IS_WINDOWS=true
fi

# ─── 색상 ───
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ─── 함수 ───
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 파일 설치 (심볼릭 링크 또는 복사)
install_file() {
    local source="$1"
    local target="$2"

    if [ "$IS_WINDOWS" = true ]; then
        # Windows: 파일 복사
        if [ -f "$target" ]; then
            if diff -q "$source" "$target" > /dev/null 2>&1; then
                log_info "이미 최신: $(basename "$target")"
                return 0
            else
                log_warn "파일 업데이트: $(basename "$target")"
            fi
        fi
        cp "$source" "$target"
        log_info "복사 완료: $(basename "$target")"
    else
        # macOS/Linux: 심볼릭 링크
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
    fi
}

# 파일 제거
remove_file() {
    local target="$1"
    if [ -L "$target" ] || [ -f "$target" ]; then
        rm "$target"
        log_info "제거: $(basename "$target")"
    fi
}

# ─── unlink 모드 ───
if [ "$1" = "--unlink" ]; then
    echo "=== ClaudeGuide 설정 제거 ==="
    echo ""

    # guides 제거
    for guide in "$SCRIPT_DIR"/guides/*.md; do
        [ -f "$guide" ] || continue
        filename=$(basename "$guide")
        remove_file "$GUIDES_DIR/$filename"
    done

    # 글로벌 CLAUDE.md 제거
    remove_file "$CLAUDE_HOME/CLAUDE.md"

    echo ""
    log_info "설정 제거 완료"
    exit 0
fi

# ─── 메인 설치 ───
echo "=========================================="
echo "  ClaudeGuide 환경 설정"
echo "=========================================="
echo ""
echo "소스: $SCRIPT_DIR"
echo "대상: $CLAUDE_HOME"
if [ "$IS_WINDOWS" = true ]; then
    echo "모드: 파일 복사 (Windows)"
else
    echo "모드: 심볼릭 링크 (macOS/Linux)"
fi
echo ""

# 1. ~/.claude/guides 디렉토리 생성
mkdir -p "$GUIDES_DIR"
log_info "디렉토리 확인: $GUIDES_DIR"

# 2. 가이드 파일 설치
echo ""
echo "--- 가이드 파일 ---"
for guide in "$SCRIPT_DIR"/guides/*.md; do
    [ -f "$guide" ] || continue
    filename=$(basename "$guide")
    install_file "$guide" "$GUIDES_DIR/$filename"
done

# 3. 글로벌 CLAUDE.md 설치
echo ""
echo "--- 글로벌 CLAUDE.md ---"
install_file "$SCRIPT_DIR/claude-md/gmarket-global-CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"

# 4. 프로젝트별 스킬 자동 배포
echo ""
echo "--- 프로젝트 스킬 배포 ---"

# 대상 프로젝트 목록 (projects.conf가 있으면 사용, 없으면 기본값)
PROJECTS_CONF="$SCRIPT_DIR/projects.conf"
PROJECTS=()

if [ -f "$PROJECTS_CONF" ]; then
    while IFS= read -r line; do
        # 빈 줄, 주석(#) 무시
        [[ -z "$line" || "$line" == \#* ]] && continue
        # ~ 를 $HOME으로 치환
        line="${line/#\~/$HOME}"
        PROJECTS+=("$line")
    done < "$PROJECTS_CONF"
    log_info "projects.conf에서 ${#PROJECTS[@]}개 프로젝트 로드"
else
    log_warn "projects.conf 없음. 스킬 배포 건너뜀."
    log_info "프로젝트를 등록하려면 projects.conf를 생성하세요:"
    echo ""
    echo "  예시 (projects.conf):"
    echo "    # 한 줄에 프로젝트 경로 하나"
    echo "    ~/AndroidStudioProjects/MoneyTalk"
    echo "    ~/AndroidStudioProjects/Gmarket"
    echo ""
fi

# 각 프로젝트에 모든 스킬 배포
for project in "${PROJECTS[@]}"; do
    if [ ! -d "$project" ]; then
        log_warn "프로젝트 경로 없음 (건너뜀): $project"
        continue
    fi

    echo ""
    log_info "프로젝트: $project"

    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        target_dir="$project/.claude/skills/$skill_name"

        mkdir -p "$target_dir"

        for skill_file in "$skill_dir"*.md; do
            [ -f "$skill_file" ] || continue
            filename=$(basename "$skill_file")
            install_file "$skill_file" "$target_dir/$filename"
        done
    done
done
echo ""

# 5. Windows 주의사항
if [ "$IS_WINDOWS" = true ]; then
    echo "--- Windows 주의사항 ---"
    echo ""
    log_warn "Windows에서는 파일 복사 방식이므로, 원본 수정 시 ./setup.sh를 다시 실행하세요."
    log_info "또는 Claude가 가이드 작업 시 자동으로 양쪽을 동기화합니다."
    echo ""
fi

# 6. 완료
echo "=========================================="
echo -e "  ${GREEN}설정 완료${NC}"
echo "=========================================="
echo ""
echo "검증:"
echo "  ls -la $GUIDES_DIR/"
echo "  ls -la $CLAUDE_HOME/CLAUDE.md"
echo ""
