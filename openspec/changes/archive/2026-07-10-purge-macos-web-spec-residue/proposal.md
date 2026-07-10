## Summary

Remove residual macOS (and one leftover Web) platform descriptions from the normative bodies of seven live specs so the spec contract matches the current iOS/iPadOS-only reality established by the archived remove-macos and remove-web-backend changes.

## Motivation

The remove-macos change (archived 2026-07-10) purged macOS from the codebase and the Xcode project, but its spec delta updated only the monorepo-layout build scenario — it did not touch the feature-spec bodies. As a result seven live specs still normatively describe macOS behavior (card layouts, preferences window, context-menu-only actions, "all three builds"), and order-batch-status-update additionally still lists Web, which remove-web-backend removed from the product. Per the repository doc-sync rule, a spec that contradicts the current reality is worse than a missing one. This change brings the spec contract in line with the shipped iOS/iPadOS-only app, so future readers and implementers are not misled into building macOS/Web behavior that no longer exists.

## Proposed Solution

For each affected requirement, emit a MODIFIED delta that reproduces the requirement in its final iOS/iPadOS-only form: strip macOS/Web from platform enumerations, drop every macOS-only scenario, and rewrite the two "platform-adaptive card vs List" requirements to describe only the surviving iOS/iPadOS system-List presentation. All iOS/iPadOS wording, examples, and scenarios are preserved verbatim; no behavior changes.

Per-spec edits:

- ai-order-summary: "AI summary entry point gated by setting" drops "and macOS" from the toolbar-action platform list. "Disabled-state prompt alert with deep link to settings" drops the "; on macOS it SHALL open the standard preferences window" clause and removes the "Navigate to settings (macOS)" scenario.
- data-model-codegen: "Generated Swift owns the data shape and handwritten extensions own behavior" — the "Apple platforms build and tests pass after the split" scenario changes "the iOS, iPadOS, and macOS builds" to "the iOS and iPadOS builds" and "all three builds SHALL succeed" to "both builds SHALL succeed". Existing apps/apple output paths in this requirement are left unchanged (owned by the follow-up rename change).
- lookup-management: "Platform-adaptive lookup management presentation" is rewritten to specify only the iOS/iPadOS system List and its "macOS renders the card layout" scenario is removed. "Lookup item management operations are preserved across platforms" removes the "macOS rename and delete use the context menu" scenario and drops macOS-era "platform layout" framing. "Reconciliation status is a managed lookup kind" drops "Design System card on macOS," from its presentation clause. "Payment method editing via the editor sheet" removes "macOS context menu" from the entry-point list.
- option-picker: "Platform-adaptive option picker presentation" is rewritten to specify only the iOS/iPadOS system List and its "macOS renders the card layout" scenario is removed.
- order-batch-status-update: "Orders list provides a multi-select mode" changes "on iOS, iPadOS, macOS, and Web" to "on iOS and iPadOS". "Batch status persistence is atomic on Apple" changes "Apple platforms (iOS, iPadOS, macOS)" to "Apple platforms (iOS and iPadOS)".
- order-category-filter: "Category filter on the orders list" drops "and macOS". "Category filter is presented as a trigger button with a searchable picker sheet" replaces every "iPadOS and macOS" / "iPadOS or macOS" with "iPadOS" across its body, example, and scenarios (the trigger-button presentation maps to the iPad regular size class; the iOS Compact filter-sheet path is unchanged).
- order-merge: "Order merge entry points" drops "and macOS" from the entry-point platform list.

## Non-Goals

- TBD Purpose placeholders: all seven affected specs (and other specs beyond them) carry a "TBD - Update Purpose after archive" Purpose line. Filling these is a separate repository-wide placeholder-cleanup concern and is out of scope here.
- data-model-codegen "Kotlin and TypeScript emitters are locked by golden-file tests": its Web/TypeScript references denote future codegen language targets — the emitters still exist and are golden-locked — not the removed Web app, so this requirement is not modified.
- monorepo-layout: its macOS reference ("no macOS build SHALL be attempted") is the correct post-removal statement, not residue, so it is not modified. Its Purpose-line staleness ("future Android, Web, and Backend") is Purpose text, not delta-modifiable, and out of scope.
- The apps/apple to apps/ios directory rename: handled by a separate follow-up change; this change keeps existing apps/apple paths unchanged.
- Archived changes under openspec/changes/archive/: immutable history, not touched.
- No source, resource, build-setting, or runtime behavior change — spec text only.

## Impact

- Affected specs: ai-order-summary, data-model-codegen, lookup-management, option-picker, order-batch-status-update, order-category-filter, order-merge (all MODIFIED)
- Affected code:
  - Modified: none (spec-only change)
  - New: none
  - Removed: none
