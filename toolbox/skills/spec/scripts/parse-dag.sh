#!/bin/bash
# Spec Parse DAG - ROADMAP の依存関係テーブルから Feature DAG をパースし Wave 分割を計算
# Usage: parse-dag.sh <ROADMAP.md> [--waves|--json|--mermaid]
#
# モード:
#   --waves   (デフォルト) Wave 分析を表示
#   --json    project-state.json の features セクション用 JSON を出力
#   --mermaid Mermaid DAG グラフを出力
#
# Exit codes:
#   0 - 成功
#   1 - 入力エラー（ファイル不在、テーブル不在、未定義依存）
#   2 - 循環依存検出

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ============================================================================
# 引数パース
# ============================================================================
ROADMAP_PATH=""
MODE="waves"

for arg in "$@"; do
    case "$arg" in
        --waves)   MODE="waves" ;;
        --json)    MODE="json" ;;
        --mermaid) MODE="mermaid" ;;
        --help|-h)
            echo "Usage: $(basename "$0") <ROADMAP.md> [--waves|--json|--mermaid]"
            echo ""
            echo "Modes:"
            echo "  --waves   (default) Wave analysis output"
            echo "  --json    JSON output for project-state.json"
            echo "  --mermaid Mermaid DAG graph output"
            exit 0
            ;;
        *)
            if [[ -z "$ROADMAP_PATH" ]]; then
                ROADMAP_PATH="$arg"
            else
                error "Unknown argument: $arg"
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$ROADMAP_PATH" ]]; then
    error "ROADMAP.md のパスを指定してください"
    echo "Usage: $(basename "$0") <ROADMAP.md> [--waves|--json|--mermaid]" >&2
    exit 1
fi

if [[ ! -f "$ROADMAP_PATH" ]]; then
    error "ROADMAP.md が見つかりません: $ROADMAP_PATH"
    exit 1
fi

# ============================================================================
# テーブルパース
# ============================================================================

# 配列: 順序保持のためインデックスベースで管理
declare -a FEATURE_IDS=()       # F-001, F-002, ...
declare -A FEATURE_NAME=()      # ID → Feature名
declare -A FEATURE_SLUG=()      # ID → スラッグ
declare -A FEATURE_DEPS=()      # ID → "F-001,F-004" (カンマ区切り)
declare -A FEATURE_SIZE=()      # ID → 規模 (S/M/L/XL)
declare -A FEATURE_WAVE=()      # ID → Wave番号 (計算結果)

# テーブル行を抽出（ヘッダ行とセパレータ行を除外）
TABLE_FOUND=false
while IFS= read -r line; do
    # パイプで始まる行のみ対象
    [[ "$line" =~ ^[[:space:]]*\| ]] || continue

    # セパレータ行（|---|---| 形式）をスキップ
    if [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*[-:]+[[:space:]]*\| ]]; then
        continue
    fi

    # ヘッダ行（ID を含む行）をスキップ
    if echo "$line" | grep -qiE '\|\s*ID\s*\|'; then
        TABLE_FOUND=true
        continue
    fi

    # テーブルが見つかっていない場合はスキップ
    [[ "$TABLE_FOUND" == true ]] || continue

    # F-XXX パターンを含む行のみ処理
    if ! echo "$line" | grep -qE 'F-[0-9]+'; then
        continue
    fi

    # カラムを分割（先頭と末尾の | を除去してから split）
    cleaned=$(echo "$line" | sed 's/^[[:space:]]*|//;s/|[[:space:]]*$//')

    # IFS=| で分割
    IFS='|' read -ra cols <<< "$cleaned"

    # 最低4カラム必要（ID, Feature, スラッグ, depends_on）
    if [[ ${#cols[@]} -lt 4 ]]; then
        continue
    fi

    # 各フィールドを trim
    id=$(echo "${cols[0]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    name=$(echo "${cols[1]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    slug=$(echo "${cols[2]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    deps_raw=$(echo "${cols[3]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # 規模（6番目のカラム、インデックス5）
    size=""
    if [[ ${#cols[@]} -ge 6 ]]; then
        size=$(echo "${cols[5]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi

    # ID バリデーション
    if ! [[ "$id" =~ ^F-[0-9]+$ ]]; then
        continue
    fi

    # depends_on をパース（「なし」「-」「空」→ 空文字列、それ以外はカンマ区切り）
    deps=""
    if [[ "$deps_raw" != "なし" && "$deps_raw" != "-" && "$deps_raw" != "None" && -n "$deps_raw" ]]; then
        # カンマ+スペースで分割し、各要素を trim
        deps=$(echo "$deps_raw" | sed 's/[[:space:]]*,[[:space:]]*/,/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi

    FEATURE_IDS+=("$id")
    FEATURE_NAME["$id"]="$name"
    FEATURE_SLUG["$id"]="$slug"
    FEATURE_DEPS["$id"]="$deps"
    FEATURE_SIZE["$id"]="$size"

done < "$ROADMAP_PATH"

# テーブルが見つからなかった
if [[ "$TABLE_FOUND" != true ]] || [[ ${#FEATURE_IDS[@]} -eq 0 ]]; then
    error "依存関係テーブルが見つかりません: $ROADMAP_PATH"
    error "テーブルには | ID | Feature | スラッグ | depends_on | ... のヘッダが必要です"
    exit 1
fi

info "${#FEATURE_IDS[@]} features をパースしました"

# ============================================================================
# 依存先バリデーション（未定義 ID への参照チェック）
# ============================================================================
HAS_UNDEFINED=false
for id in "${FEATURE_IDS[@]}"; do
    deps="${FEATURE_DEPS[$id]}"
    [[ -z "$deps" ]] && continue

    IFS=',' read -ra dep_list <<< "$deps"
    for dep in "${dep_list[@]}"; do
        dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -z "${FEATURE_NAME[$dep]+x}" ]]; then
            error "未定義の Feature ID への依存: $id → $dep"
            HAS_UNDEFINED=true
        fi
    done
done

if [[ "$HAS_UNDEFINED" == true ]]; then
    exit 1
fi

# ============================================================================
# 循環依存検出（DFS）
# ============================================================================
# 状態: 0=未訪問, 1=訪問中（スタック上）, 2=完了
declare -A VISIT_STATE=()
declare -a DFS_STACK=()
CYCLE_DETECTED=false
CYCLE_PATH=""

dfs_check_cycle() {
    local node="$1"
    VISIT_STATE["$node"]=1
    DFS_STACK+=("$node")

    local deps="${FEATURE_DEPS[$node]}"
    if [[ -n "$deps" ]]; then
        IFS=',' read -ra dep_list <<< "$deps"
        for dep in "${dep_list[@]}"; do
            dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            local state="${VISIT_STATE[$dep]:-0}"

            if [[ "$state" -eq 1 ]]; then
                # 循環検出 - パスを構築
                CYCLE_DETECTED=true
                local cycle_start=false
                CYCLE_PATH=""
                for s in "${DFS_STACK[@]}"; do
                    if [[ "$s" == "$dep" ]]; then
                        cycle_start=true
                    fi
                    if [[ "$cycle_start" == true ]]; then
                        if [[ -n "$CYCLE_PATH" ]]; then
                            CYCLE_PATH="$CYCLE_PATH → "
                        fi
                        CYCLE_PATH="$CYCLE_PATH$s"
                    fi
                done
                CYCLE_PATH="$CYCLE_PATH → $dep"
                return 1
            elif [[ "$state" -eq 0 ]]; then
                if ! dfs_check_cycle "$dep"; then
                    return 1
                fi
            fi
        done
    fi

    # スタックからポップ
    unset 'DFS_STACK[${#DFS_STACK[@]}-1]'
    VISIT_STATE["$node"]=2
    return 0
}

for id in "${FEATURE_IDS[@]}"; do
    if [[ "${VISIT_STATE[$id]:-0}" -eq 0 ]]; then
        if ! dfs_check_cycle "$id"; then
            break
        fi
    fi
done

if [[ "$CYCLE_DETECTED" == true ]]; then
    error "循環依存を検出しました: $CYCLE_PATH"
    exit 2
fi

# ============================================================================
# Wave 計算（トポロジカルソート - BFS レベル分け）
# ============================================================================

# 各ノードの入次数を計算
declare -A IN_DEGREE=()
for id in "${FEATURE_IDS[@]}"; do
    IN_DEGREE["$id"]=0
done

for id in "${FEATURE_IDS[@]}"; do
    deps="${FEATURE_DEPS[$id]}"
    [[ -z "$deps" ]] && continue
    IFS=',' read -ra dep_list <<< "$deps"
    for dep in "${dep_list[@]}"; do
        dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        IN_DEGREE["$id"]=$(( ${IN_DEGREE[$id]} + 1 ))
    done
done

# Wave 1: 入次数 0 のノード
declare -a CURRENT_WAVE=()
for id in "${FEATURE_IDS[@]}"; do
    if [[ "${IN_DEGREE[$id]}" -eq 0 ]]; then
        CURRENT_WAVE+=("$id")
        FEATURE_WAVE["$id"]=1
    fi
done

WAVE_NUM=1
declare -A WAVE_MEMBERS=()  # Wave番号 → "F-001,F-003" (カンマ区切り)
WAVE_MEMBERS[$WAVE_NUM]=$(IFS=','; echo "${CURRENT_WAVE[*]}")

# BFS で次の Wave を計算
declare -A PROCESSED=()
for id in "${CURRENT_WAVE[@]}"; do
    PROCESSED["$id"]=1
done

while true; do
    declare -a NEXT_WAVE=()

    for id in "${FEATURE_IDS[@]}"; do
        # 既に処理済みならスキップ
        [[ -n "${PROCESSED[$id]+x}" ]] && continue

        # 全依存が処理済みか確認
        deps="${FEATURE_DEPS[$id]}"
        [[ -z "$deps" ]] && continue

        all_resolved=true
        IFS=',' read -ra dep_list <<< "$deps"
        for dep in "${dep_list[@]}"; do
            dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ -z "${PROCESSED[$dep]+x}" ]]; then
                all_resolved=false
                break
            fi
        done

        if [[ "$all_resolved" == true ]]; then
            NEXT_WAVE+=("$id")
        fi
    done

    # 次の Wave がなければ終了
    [[ ${#NEXT_WAVE[@]} -eq 0 ]] && break

    WAVE_NUM=$(( WAVE_NUM + 1 ))
    for id in "${NEXT_WAVE[@]}"; do
        FEATURE_WAVE["$id"]=$WAVE_NUM
        PROCESSED["$id"]=1
    done
    WAVE_MEMBERS[$WAVE_NUM]=$(IFS=','; echo "${NEXT_WAVE[*]}")
done

TOTAL_WAVES=$WAVE_NUM
TOTAL_FEATURES=${#FEATURE_IDS[@]}

# 最大並列数を計算
MAX_PARALLEL=0
for w in $(seq 1 "$TOTAL_WAVES"); do
    IFS=',' read -ra members <<< "${WAVE_MEMBERS[$w]}"
    count=${#members[@]}
    if [[ $count -gt $MAX_PARALLEL ]]; then
        MAX_PARALLEL=$count
        MAX_PARALLEL_WAVE=$w
    fi
done

# ============================================================================
# 出力
# ============================================================================

# スラッグから依存先のスラッグリストを取得するヘルパー
get_dep_slugs() {
    local id="$1"
    local deps="${FEATURE_DEPS[$id]}"
    [[ -z "$deps" ]] && return

    local result=""
    IFS=',' read -ra dep_list <<< "$deps"
    for dep in "${dep_list[@]}"; do
        dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -n "$result" ]]; then
            result="$result, ${FEATURE_SLUG[$dep]}"
        else
            result="${FEATURE_SLUG[$dep]}"
        fi
    done
    echo "$result"
}

# 依存先の ID リストを表示用に取得するヘルパー
get_dep_ids() {
    local id="$1"
    local deps="${FEATURE_DEPS[$id]}"
    [[ -z "$deps" ]] && return
    echo "$deps"
}

case "$MODE" in
    # ------------------------------------------------------------------
    # --waves モード
    # ------------------------------------------------------------------
    waves)
        echo ""
        echo -e "${BOLD}${CYAN}=== Wave Analysis ===${NC}"

        for w in $(seq 1 "$TOTAL_WAVES"); do
            echo ""
            if [[ $w -eq 1 ]]; then
                echo -e "${BOLD}Wave $w (依存なし):${NC}"
            else
                echo -e "${BOLD}Wave $w:${NC}"
            fi

            IFS=',' read -ra members <<< "${WAVE_MEMBERS[$w]}"
            for id in "${members[@]}"; do
                slug="${FEATURE_SLUG[$id]}"
                size="${FEATURE_SIZE[$id]}"
                name="${FEATURE_NAME[$id]}"
                dep_ids=$(get_dep_ids "$id")

                # カラム整形
                printf "  %-6s  %-14s %s  %s" "$id" "$slug" "$size" "$name"
                if [[ -n "$dep_ids" ]]; then
                    printf " (%s %s)" "←" "$dep_ids"
                fi
                echo ""
            done
        done

        echo ""
        echo -e "Total: ${BOLD}$TOTAL_FEATURES${NC} features, ${BOLD}$TOTAL_WAVES${NC} waves"
        echo -e "Max parallel (Wave $MAX_PARALLEL_WAVE): ${BOLD}$MAX_PARALLEL${NC}"
        echo ""
        ;;

    # ------------------------------------------------------------------
    # --json モード
    # ------------------------------------------------------------------
    json)
        echo "{"
        first=true
        for id in "${FEATURE_IDS[@]}"; do
            slug="${FEATURE_SLUG[$id]}"
            wave="${FEATURE_WAVE[$id]}"
            deps="${FEATURE_DEPS[$id]}"

            # depends_on を JSON 配列に変換
            dep_json="[]"
            if [[ -n "$deps" ]]; then
                dep_json="["
                dep_first=true
                IFS=',' read -ra dep_list <<< "$deps"
                for dep in "${dep_list[@]}"; do
                    dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    dep_slug="${FEATURE_SLUG[$dep]}"
                    if [[ "$dep_first" == true ]]; then
                        dep_json="$dep_json\"$dep_slug\""
                        dep_first=false
                    else
                        dep_json="$dep_json, \"$dep_slug\""
                    fi
                done
                dep_json="$dep_json]"
            fi

            if [[ "$first" == true ]]; then
                first=false
            else
                echo ","
            fi
            printf '  "%s": { "issue_number": null, "status": "pending", "depends_on": %s, "wave": %d }' \
                "$slug" "$dep_json" "$wave"
        done
        echo ""
        echo "}"
        ;;

    # ------------------------------------------------------------------
    # --mermaid モード
    # ------------------------------------------------------------------
    mermaid)
        echo "graph LR"
        for id in "${FEATURE_IDS[@]}"; do
            slug="${FEATURE_SLUG[$id]}"
            deps="${FEATURE_DEPS[$id]}"
            [[ -z "$deps" ]] && continue

            IFS=',' read -ra dep_list <<< "$deps"
            for dep in "${dep_list[@]}"; do
                dep=$(echo "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                dep_slug="${FEATURE_SLUG[$dep]}"
                echo "    ${dep}[${dep_slug}] --> ${id}[${slug}]"
            done
        done
        ;;
esac
