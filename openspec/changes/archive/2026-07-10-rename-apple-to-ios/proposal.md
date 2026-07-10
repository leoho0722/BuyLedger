## Summary

Rename the Apple deployable-unit directory from apps/apple to apps/ios so the folder name reflects the iOS/iPadOS-only reality and matches its apps/android sibling, updating every hand-authored reference while the Xcode project moves intact.

## Motivation

After the archived remove-macos change (code) and purge-macos-web-spec-residue change (specs), apps/apple holds only the iOS/iPadOS universal app. The user decided to switch the directory's naming axis from platform ecosystem (apple) to operating system (ios), aligning it with apps/android. A discovery audit (six category sweeps plus an adversarial completeness critic) established the complete reference set and confirmed the directory move is safe without touching any Xcode project file. The layout contract in the monorepo-layout spec currently mandates the apps/apple prefix, so it must be reworded, not merely path-substituted.

## Proposed Solution

Move the directory (git mv apps/apple apps/ios), which the audit verified is Xcode-safe: project.pbxproj holds zero apps/apple occurrences and zero absolute paths (projectDirPath and projectRoot are both empty), the scheme uses a relative container reference, and the workspace uses a self location — so all internal file references are project-relative and the bundle moves cleanly with no pbxproj, scheme, or workspace edits.

Then, in the same change, update the two build-critical references, regenerate codegen, update documentation, and reword the two affected spec contracts:

- Build-critical (must land together with the move): rewrite the two .gitignore secret-ignore rules (the Config.xcconfig and GoogleService-Info.plist paths) so the secrets stay ignored at their new location; rewrite the Swift target output path in the cross-platform generator config so codegen writes generated Swift into apps/ios, then regenerate (bun run generate) and gate (bun run check).
- Documentation: rewrite apps/apple references in the root README.md, CLAUDE.md, and AGENTS.md; rewrite the apps/apple self-references inside the moved apps/ios README.md and CLAUDE.md; update the apps/apple mention in the generator config comment and the generator test-title string.
- Spec contracts: reword monorepo-layout's three affected requirements (Deployable units are rooted under apps/, Reserved future directories are documented not stubbed, Committed path references track the actual layout) to anchor the Apple project at apps/ios, including the non-obvious "apps/ SHALL contain only apple" scenario line which becomes "apps/ SHALL contain only ios" and adding AGENTS.md to the enumerated root-anchored files; reword data-model-codegen's Generated Swift owns the data shape requirement so the generated-file output path is apps/ios.
- Verification: build the app on the iOS simulator and the iPadOS simulator (both succeed, confirming compact and regular layouts), run the iOS test suite, and run the codegen check (exit 0).

## Non-Goals

- @trace metadata blocks in spec files: auto-generated and self-healing at archive time; not hand-edited.
- Archived changes under openspec/changes/archive/: immutable history, not touched (they will forever reference apps/apple, an accepted history-vs-present gap).
- Xcode project internals: the audit verified the move needs no pbxproj, scheme, or workspace edits; scheme name and bundle identifiers are unchanged.
- monorepo-layout Purpose text: the Purpose section is not modifiable via a delta spec; its pre-existing staleness is out of scope.
- TBD Purpose placeholders across specs: a separate repository-wide concern, unchanged here.
- The stale root symlinks .compile and buildServer.json: they resolve to the legacy repository-root BuyLedger/ tree, not apps/apple, and are gitignored — unrelated to this rename.
- No source, resource, or build-setting change inside the Xcode project; no runtime behavior change.

## Impact

- Affected specs: monorepo-layout (MODIFIED), data-model-codegen (MODIFIED)
- Affected code:
  - Renamed: apps/apple to apps/ios (entire directory, including BuyLedger.xcodeproj and the generated Swift under apps/ios/BuyLedger/Core/Domain/Generated)
  - Modified: .gitignore, shared/data-model/codegen.yaml, shared/data-model/generator/test/datamodel-gen.test.ts, README.md, CLAUDE.md, AGENTS.md, apps/ios/README.md, apps/ios/CLAUDE.md
  - New: none
  - Removed: none
