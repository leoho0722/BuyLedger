#!/bin/bash
#
# PreToolUse hook：執行完整 UI 主回歸前要求使用者確認
#
# 完整 UI 主回歸只在 change 的最終驗收跑一次 (apps/ios/CLAUDE.md「UI 測試」)
# 偵測條件：`-only-testing:BuyLedgerUITests` 沒有指定類別，
# 或 CLI 以 BuyLedgerUITests scheme 執行測試卻沒有任何 `-only-testing:BuyLedgerUITests/<類別>`
# MCP 的 test_sim 取不到 session 預設的 scheme，沒帶 -only-testing 的執行不在偵測範圍

set -euo pipefail

payload="$(cat)"
tool_name="$(jq -r '.tool_name // empty' <<<"$payload")"

case "$tool_name" in
    mcp__XcodeBuildMCP__test_sim)
        args="$(jq -r '(.tool_input.extraArgs // []) | join(" ")' <<<"$payload")"
        is_cli_ui_scheme=false
        ;;
    Bash)
        args="$(jq -r '.tool_input.command // empty' <<<"$payload")"
        # 只檢查 mobilebuildmcp 的測試指令
        if ! grep -qE 'mobilebuildmcp[^|;&]*(simulator|device)[[:space:]]+test' <<<"$args"; then
            exit 0
        fi
        is_cli_ui_scheme=false
        if grep -qE -- '--scheme[[:space:]=]+BuyLedgerUITests([[:space:]]|$)' <<<"$args"; then
            is_cli_ui_scheme=true
        fi
        ;;
    *)
        exit 0
        ;;
esac

has_whole_target=false
if grep -qE -- '-only-testing:BuyLedgerUITests([[:space:]"'"'"']|$)' <<<"$args"; then
    has_whole_target=true
fi

has_class_filter=false
if grep -qE -- '-only-testing:BuyLedgerUITests/' <<<"$args"; then
    has_class_filter=true
fi

if [ "$has_whole_target" = true ] \
    || { [ "$is_cli_ui_scheme" = true ] && [ "$has_class_filter" = false ]; }; then
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "ask",
            permissionDecisionReason: "即將執行完整 UI 主回歸。完整回歸只在 change 的最終驗收跑一次；中途的 task 與合併各自已驗證的分支只跑受影響類別 (apps/ios/CLAUDE.md「UI 測試」)。確定要跑完整回歸嗎？"
        }
    }'
fi

exit 0
