<!-- SPECTRA:START v1.3.0 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `$spectra-*` skills when:

- An explicitly requested Spectra decision needs structure → `$spectra-discuss`
- User explicitly requests a Spectra change proposal → `$spectra-propose`
- Continue tasks for an identified change → `$spectra-apply`
- Update requirements or plans for an identified change → `$spectra-ingest`
- Check implementation matches artifacts → `$spectra-verify`
- Review implementation quality and logic issues → `$spectra-review`
- Analyze artifact consistency before coding → `$spectra-analyze`
- Audit security sharp edges → `$spectra-audit`
- Check stale changes before resuming → `$spectra-drift`
- Debug a concrete bug systematically → `$spectra-debug`
- Implementation is done → `$spectra-archive`
- Commit only files related to a specific change → `$spectra-commit`

Explicit skill invocation takes precedence. Apply existing authorization within its unchanged scope.

## Workflow

discuss? → propose → apply ⇄ ingest → verify / review → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode (`/plan`) → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `$spectra-apply` and `$spectra-ingest` skills disclose parking and restore when the named operation is already explicitly requested; respect a known refusal, otherwise ask for missing authorization.

<!-- SPECTRA:END -->

# 儲存庫指引

本檔只記錄 Codex 專屬差異；跨平台通用規範以 [`CLAUDE.md`](CLAUDE.md) 為準，各平台與 shared 模組的硬規則與隱性 gotcha 見該目錄的 `CLAUDE.md` (如 [`apps/ios/CLAUDE.md`](apps/ios/CLAUDE.md)、[`shared/data-model/CLAUDE.md`](shared/data-model/CLAUDE.md))，專案概覽見 [`README.md`](README.md)，Apple 平台 setup 見 [`apps/ios/README.md`](apps/ios/README.md)。

讀取規格時，`openspec/specs/**/spec.md` 尾端的 `<!-- @trace -->` 區塊是工具生成的歷史紀錄，所列路徑未經驗證；判斷程式碼現況一律以搜尋程式碼本身為準，不得以 trace 區塊推論現有結構。

## Codex 專屬差異

- 由 Codex 建立或 amend 的 commit 結尾加 Co-Authored-By trailer：display name 直接寫當次實際使用的模型全名 (如 `GPT-6 Astra`)，不加 `Codex` 前綴、不用括號包住模型名，email 固定 `codex@openai.com`；不回溯修改既有提交。

```text
refactor(time): 時間相依改走 @Dependency(\.date) 注入

- DashboardView / InsightsView / RootFeature 加 @Dependency(\.date)
- OrdersFeature.State.filteredOrders 改成 func(referenceDate:)
- 新增 TestDependencies.fixedNow 給 snapshot 與 unit test 共用

Co-Authored-By: GPT-6 Astra <codex@openai.com>
```
