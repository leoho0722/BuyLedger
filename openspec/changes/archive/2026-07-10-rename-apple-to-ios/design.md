## Context

The rename-apple-to-ios change moves the Apple deployable-unit directory apps/apple to apps/ios. A discovery audit — six category sweeps plus an adversarial completeness and safety critic — produced the complete, verified reference set and a Xcode-move safety verdict. This design records the migration sequence, why certain edits must land atomically with the directory move, the safety evidence, and the exact scope, so the change survives being parked or handed to another agent.

## Xcode-move safety (verified by audit)

git mv apps/apple apps/ios keeps BuyLedger.xcodeproj building with NO edits to project.pbxproj, the scheme, or the workspace:

- project.pbxproj holds zero apps/apple occurrences and zero absolute paths; projectDirPath and projectRoot are both empty strings, so every file reference is project-relative.
- BuyLedger.xcscheme uses a relative container reference (container:BuyLedger.xcodeproj) with no apps/apple and no absolute paths.
- project.xcworkspace/contents.xcworkspacedata uses location = self.
- No Info.plist, entitlements, Package.resolved, or xcconfig inside the bundle self-references the path; there is no nested .git; no CI, Fastlane, or DerivedData path reference exists.

The directory move is therefore mechanical. The scheme name and bundle identifiers are unchanged.

## Migration sequence (order matters)

1. Move the directory: git mv apps/apple apps/ios (single move; git preserves history and the intact Xcode bundle).
2. Rewrite the build-critical references so the moved tree is coherent BEFORE any build or codegen:
   - .gitignore: the two secret-ignore rules for Config.xcconfig and GoogleService-Info.plist, apps/apple to apps/ios. A stale ignore path un-ignores the local API-key xcconfig and the Firebase plist, so they could be committed by accident — this is the highest-risk edit and must not be skipped.
   - shared/data-model/codegen.yaml: the Swift target output path ../../apps/apple/... to ../../apps/ios/..., plus the line-2 comment. The generator writes generated Swift to this path; a stale value makes generate write to the wrong location and check drift.
3. Regenerate and gate codegen: run bun run generate then bun run check in shared/data-model/generator; both must exit 0, confirming the generated Swift now lives under apps/ios and matches the schema.
4. Rewrite documentation references (non-build-critical): root README.md, CLAUDE.md, and AGENTS.md; the apps/apple self-references inside the moved apps/ios/README.md and apps/ios/CLAUDE.md; the apps/apple mention in the generator config comment and the generator test-title string in datamodel-gen.test.ts.
5. The two spec deltas (authored in this change as MODIFIED delta specs) apply to the main specs at archive time: monorepo-layout (three requirements) and data-model-codegen (one requirement).
6. Verify: build on the iOS simulator and the iPadOS simulator (both succeed, confirming compact and regular layouts), run the iOS test suite (all pass), and re-confirm the codegen check exits 0.

## Non-obvious edits

- monorepo-layout requirement Reserved future directories are documented, not stubbed contains a scenario line "apps/ SHALL contain only apple" — this is the bare directory name, not the apps/apple path token, so a path grep misses it. It becomes "apps/ SHALL contain only ios".
- monorepo-layout requirement Committed path references track the actual layout enumerates the root-anchored files that must track the layout (README.md, CLAUDE.md, .gitignore, and openspec spec files) and mandates the apps/apple prefix. Reword the prefix to apps/ios AND add AGENTS.md to the enumerated list, because AGENTS.md carries apps/apple links. Its stale-path-scan scenario keeps checking for the pre-restructure BuyLedger/BuyLedger prefix (unchanged), and its scope is clarified to hand-authored references, excluding archived changes and auto-generated @trace metadata.
- The generated Swift files under apps/ios/BuyLedger/Core/Domain/Generated move with the directory; step 3 rewrites them in place (identical content, new location) and check confirms parity. Generated files are never hand-edited (they are read-only per the project rule).

## Scope boundaries

In scope: the directory move; the two build-critical edits plus codegen regeneration; the documentation edits; the two spec-delta rewrites; and build, test, and codegen verification.

Out of scope: @trace metadata (auto-generated, self-heals at archive); openspec/changes/archive/ (immutable history); Xcode project internals (verified to need no edits); monorepo-layout Purpose text (not delta-modifiable); TBD Purpose placeholders across specs (separate repository-wide concern); the .compile and buildServer.json root symlinks (they resolve to the legacy repository-root BuyLedger/ tree, not apps/apple, and are gitignored); and .vscode/launch.json (uses the workspace name, not the path).

## Implementation Contract

- Observable outcome: the repository has no apps/apple directory; the Apple app lives at apps/ios with an intact, building Xcode project; no hand-authored apps/apple reference remains anywhere except archived changes and auto-generated @trace metadata.
- Build-critical invariants: .gitignore still ignores the two secret files at their apps/ios paths; codegen writes generated Swift to apps/ios and the codegen check passes.
- Verification targets: the iOS simulator build succeeds; the iPadOS simulator build succeeds; the iOS test suite passes; bun run check in shared/data-model/generator exits 0; git check-ignore confirms both secret files are ignored at their apps/ios paths; and a repository grep excluding archive/ and @trace blocks for apps/apple returns zero hand-authored hits.
- Failure modes to avoid: committing secrets because a .gitignore path went stale; codegen drift because the output path went stale; hand-editing generated files; and touching archived specs or Xcode project internals.
