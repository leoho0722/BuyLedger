<!--
遷移序列見 design.md。順序硬性：git mv 先 → build-critical 編輯 → codegen 重生 → doc (可平行) → build/test 驗證。
spec delta (monorepo-layout / data-model-codegen) 於封存時套用，apply 不手改主 spec。
tdd:true — 本 change 無新增行為，回歸守門為既有 iOS 測試套件 + codegen check + build，須全綠。
audit:true — .gitignore 機密 ignore-rule 為安全敏感邊角，1.2 以 git check-ignore 明確驗證。
-->

## 1. Move the directory and fix build-critical references

- [x] 1.1 Rename the Apple deployable unit so the project resides at apps/ios (satisfies Requirement: Deployable units are rooted under apps/): move apps/apple to apps/ios with a single git mv, preserving the intact Xcode bundle and git history; no pbxproj/scheme/workspace edit is needed (audit-verified relative paths). Verify: apps/apple no longer exists, apps/ios/BuyLedger.xcodeproj exists, and `git status` records the paths as renames (not delete+add).
- [x] 1.2 Keep the two local secret files ignored at their new location: rewrite the .gitignore ignore-rules for Config.xcconfig and GoogleService-Info.plist from the apps/apple prefix to apps/ios (part of Requirement: Committed path references track the actual layout). Verify: `git check-ignore -v apps/ios/BuyLedger/Resources/Config.xcconfig` and the GoogleService-Info.plist path both report the .gitignore rule as the matcher, and neither secret appears in `git status`.
- [x] 1.3 Point the cross-platform codegen at the renamed directory so generated Swift lands under apps/ios (satisfies Requirement: Generated Swift owns the data shape and handwritten extensions own behavior): rewrite the Swift target output path in shared/data-model/codegen.yaml from ../../apps/apple/... to ../../apps/ios/BuyLedger/Core/Domain/Generated and update the adjacent comment, then run bun run generate and bun run check in shared/data-model/generator. Verify: both commands exit 0 and the generated files now live under apps/ios/BuyLedger/Core/Domain/Generated.

## 2. Update documentation references

- [x] 2.1 [P] Make the root documentation track the new layout (satisfies Requirement: Committed path references track the actual layout and Requirement: Reserved future directories are documented, not stubbed): rewrite every apps/apple reference in README.md, CLAUDE.md, and AGENTS.md to apps/ios (including README.md line 43's three occurrences and AGENTS.md line 32's two links). Verify: a grep for apps/apple across README.md, CLAUDE.md, and AGENTS.md returns zero matches.
- [x] 2.2 [P] Make the moved platform docs self-consistent: rewrite the apps/apple self-references inside the now-moved apps/ios/README.md and apps/ios/CLAUDE.md to apps/ios (xcodeproj path, tree label, cp and --project-path commands, cd command, DesignSystem/tests/codegen notes). Verify: a grep for apps/apple across apps/ios/README.md and apps/ios/CLAUDE.md returns zero matches.
- [x] 2.3 [P] Correct the generator test-title string for accuracy: rewrite "apps/apple" to "apps/ios" in the test title in shared/data-model/generator/test/datamodel-gen.test.ts (descriptive only; the assertion checks type names). Verify: a grep for apps/apple in that file returns zero matches and bun run test still passes.

## 3. Verify build, tests, and reference cleanliness

- [x] 3.1 Confirm both device families still build after the move (satisfies the build scenario of Requirement: Deployable units are rooted under apps/): bump CFBundleVersion once (per the build-number rule, run agvtool without -all under apps/ios), then build the app on an iOS simulator and on an iPadOS simulator against apps/ios/BuyLedger.xcodeproj with the BuyLedger scheme. Verify: both simulator builds succeed with no source, resource, or build-setting change inside the Xcode project.
- [x] 3.2 Confirm no regression from the move: run the iOS unit test suite (BuyLedgerTests) on a supported iOS 26.x simulator. Verify: the full suite passes.
- [x] 3.3 Confirm no stale hand-authored reference remains (satisfies the stale-path-scan scenario of Requirement: Committed path references track the actual layout): grep the repository for apps/apple excluding openspec/changes/archive/ and @trace metadata blocks. Verify: zero hand-authored matches remain (archived changes and auto-generated @trace legitimately retain apps/apple and are out of scope).
