#!/bin/bash
#
# 將 BuyLedger 以 Release 打包並上傳 TestFlight
#
# 版號與 build 號取自 BuyLedger target 的 Release build settings；本腳本不會遞增，執行前先提交版號
# mobilebuildmcp 沒有 archive 與 export 工具，因此本腳本直接呼叫 xcodebuild
# 變數後面緊接全形字元時要寫成 `${name}`：bash 3.2 會把多位元組字元併入變數名而展開成空字串

set -euo pipefail

usage() {
    cat <<'EOF'
用法：apps/ios/scripts/upload-testflight.sh [--export-only] [--yes]
  --export-only  只打包並匯出 .ipa 到本機，不上傳
  --yes          上傳前不再詢問確認
  -h, --help     顯示此說明

驗證方式 (擇一)：
  - 預設沿用 Xcode Settings › Accounts 已登入、可發佈 team 23JEQ2524P 的帳號
  - 同時設定 ASC_KEY_PATH (.p8 路徑)、ASC_KEY_ID、ASC_ISSUER_ID 時改用 App Store Connect API key
EOF
}

fail() {
    echo "❌ $*" >&2
    exit 1
}

# 執行 xcodebuild 並把輸出寫入 log，失敗時印出結尾方便判讀
run_logged() {
    local log="$1"
    shift
    if ! xcodebuild "$@" >"$log" 2>&1; then
        tail -n 40 "$log" >&2
        fail "xcodebuild 失敗，完整 log：${log}"
    fi
}

# 列出會進入 App 產物的路徑中尚未提交的變更，讀不到 git 狀態時中止
uncommitted_build_inputs() {
    git -C "$REPO_ROOT" status --porcelain -- "${BUILD_INPUTS[@]}" \
        || fail "無法讀取 git 狀態"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(git -C "$IOS_DIR" rev-parse --show-toplevel)"
readonly SCRIPT_DIR IOS_DIR REPO_ROOT
readonly PROJECT="$IOS_DIR/BuyLedger.xcodeproj"
readonly SCHEME="BuyLedger"
readonly TEAM_ID="23JEQ2524P"

# 會進入 App 產物的路徑，打包前必須與 HEAD 一致；打包後的變更只提示
readonly BUILD_INPUTS=(
    "apps/ios/BuyLedger"
    "apps/ios/BuyLedger.xcodeproj"
    "apps/ios/BuyLedgerAccessibilityIDs"
)

destination="upload"
assume_yes=false
for arg in "$@"; do
    case "$arg" in
        --export-only) destination="export" ;;
        --yes) assume_yes=true ;;
        -h | --help)
            usage
            exit 0
            ;;
        *) fail "未知參數：${arg} (用 --help 查看用法)" ;;
    esac
done

# 1. 前置檢查

dirty="$(uncommitted_build_inputs)"
if [[ -n "$dirty" ]]; then
    printf '%s\n' "$dirty" >&2
    fail "App 原始碼或專案檔有未提交的變更，請先 commit 或 stash"
fi

for file in Config.xcconfig GoogleService-Info.plist; do
    [[ -f "$IOS_DIR/BuyLedger/Resources/$file" ]] \
        || fail "缺少 BuyLedger/Resources/${file}，範本見同目錄的 example 檔"
done

auth_args=()
if [[ -n "${ASC_KEY_PATH:-}${ASC_KEY_ID:-}${ASC_ISSUER_ID:-}" ]]; then
    [[ -n "${ASC_KEY_PATH:-}" && -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" ]] \
        || fail "ASC_KEY_PATH、ASC_KEY_ID、ASC_ISSUER_ID 必須同時設定"
    [[ -f "$ASC_KEY_PATH" ]] || fail "找不到 API key 檔案：${ASC_KEY_PATH}"
    auth_args=(
        -authenticationKeyPath "$ASC_KEY_PATH"
        -authenticationKeyID "$ASC_KEY_ID"
        -authenticationKeyIssuerID "$ASC_ISSUER_ID"
    )
    auth_label="App Store Connect API key ($ASC_KEY_ID)"
else
    auth_label="Xcode 已登入的帳號"
fi

settings="$(
    xcodebuild -project "$PROJECT" -target "$SCHEME" -configuration Release -showBuildSettings
)" || fail "讀取 build settings 失敗"
version="$(awk -F' = ' '/^ *MARKETING_VERSION = / { print $2; exit }' <<<"$settings")"
build="$(awk -F' = ' '/^ *CURRENT_PROJECT_VERSION = / { print $2; exit }' <<<"$settings")"
[[ -n "$version" && -n "$build" ]] || fail "讀不到 MARKETING_VERSION 或 CURRENT_PROJECT_VERSION"

head_commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
tag_commit="$(git -C "$REPO_ROOT" rev-parse --short -q --verify "refs/tags/ios-v$version^{commit}" || true)"
if [[ "$tag_commit" != "$head_commit" ]]; then
    echo "⚠️  HEAD ($head_commit) 沒有標 ios-v${version}，打包內容不會對應到版本 tag" >&2
fi

echo "版本：$version ($build)，commit $head_commit"
echo "驗證：${auth_label}"
echo "目的地：$([[ "$destination" == "upload" ]] && echo "上傳 TestFlight" || echo "匯出 .ipa 到本機")"

if [[ "$destination" == "upload" && "$assume_yes" != true ]]; then
    if ! read -r -p "確定要上傳到 TestFlight？[y/N] " answer; then
        fail "無法讀取確認輸入，非互動執行請加 --yes"
    fi
    [[ "$answer" == "y" || "$answer" == "Y" ]] || fail "已取消"
fi

# 2. 封存 (Archive)

readonly STAMP="$(date +%Y%m%d-%H%M%S)"
# 放在 Xcode 預設的 Archives 目錄，Organizer 可直接看到並用於符號化
readonly ARCHIVE_PATH="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/BuyLedger-$version-$build-$STAMP.xcarchive"
readonly WORK_DIR="$IOS_DIR/build/testflight/$version-$build-$STAMP"
mkdir -p "$WORK_DIR"

echo "▶ 封存中，log：${WORK_DIR}/archive.log"
run_logged "$WORK_DIR/archive.log" archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    ${auth_args[@]+"${auth_args[@]}"}
echo "✅ 封存完成：${ARCHIVE_PATH}"

# 3. 匯出或上傳

# 關閉 manageAppVersionAndBuildNumber，避免上傳時 build 號被改成與提交內容不同
cat >"$WORK_DIR/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>$destination</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

echo "▶ $([[ "$destination" == "upload" ]] && echo "上傳" || echo "匯出")中，log：${WORK_DIR}/export.log"
run_logged "$WORK_DIR/export.log" -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$WORK_DIR/ExportOptions.plist" \
    -exportPath "$WORK_DIR/export" \
    -allowProvisioningUpdates \
    ${auth_args[@]+"${auth_args[@]}"}

if [[ "$destination" == "upload" ]]; then
    echo "✅ 已上傳 $version ($build)，App Store Connect 處理完成後會出現在 TestFlight"
else
    echo "✅ 已匯出：${WORK_DIR}/export"
fi

# 4. 打包後檢查

# Xcode build 可能改寫 .xcstrings，提醒檢查後再還原
dirty="$(uncommitted_build_inputs)"
if [[ -n "$dirty" ]]; then
    echo "⚠️  打包後 App 原始碼出現變更 (Xcode 可能改寫了 .xcstrings)，確認後再還原：" >&2
    printf '%s\n' "$dirty" >&2
fi
