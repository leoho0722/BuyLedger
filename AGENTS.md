<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `$spectra-*` skills when:

- A discussion needs structure before coding → `$spectra-discuss`
- User wants to plan, propose, or design a change → `$spectra-propose`
- Tasks are ready to implement → `$spectra-apply`
- There's an in-progress change to continue → `$spectra-ingest`
- User asks about specs or how something works → `$spectra-ask`
- Implementation is done → `$spectra-archive`
- Commit only files related to a specific change → `$spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `$spectra-apply` and `$spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

# 儲存庫指引

本檔只記錄 Codex 專屬差異；跨平台通用規範以 [`CLAUDE.md`](CLAUDE.md) 為準，各平台硬規則與隱性 gotcha 見對應平台目錄的 `CLAUDE.md` (如 [`apps/apple/CLAUDE.md`](apps/apple/CLAUDE.md))，專案概覽見 [`README.md`](README.md)，Apple 平台 setup 見 [`apps/apple/README.md`](apps/apple/README.md)。

## Codex 專屬差異

- **Commit Co-Authored-By trailer**：由 Codex 建立或 amend 的 commit，commit message 最後須加入下列 trailer，`<model-name>` 替換為當次實際使用的模型名稱：

  ```text
  Co-Authored-By: Codex (<model-name>) <codex@openai.com>
  ```
