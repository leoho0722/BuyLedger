## MODIFIED Requirements

### Requirement: Check mode detects drift between schema and committed output

The datamodel-gen CLI SHALL provide a check command that regenerates all configured targets in memory and compares the results against the files on disk. When every file matches, the command SHALL exit zero. When any file differs, is missing, or is present on disk but no longer generated, the command SHALL exit non-zero and list each drifted file path. The check command SHALL NOT modify any file on disk.

Drift detection SHALL NOT rely on a human remembering to invoke the command. The generator test suite SHALL assert that the production schema and the committed production output are in sync, and continuous integration SHALL run that suite, so that drift fails a push rather than surviving into the repository.

#### Scenario: Schema changed without regeneration

- **WHEN** a field is added to a type in the schema directory and the check command runs before generate is re-run
- **THEN** the check command SHALL exit non-zero and list the affected generated file paths for every configured target

#### Scenario: Outputs in sync

- **WHEN** the check command runs immediately after a successful generate with no further edits
- **THEN** it SHALL exit zero and SHALL NOT modify any file

#### Scenario: Production output drift fails the test suite

- **WHEN** a committed generated file under the production output directory is edited by hand and the generator test suite runs
- **THEN** the suite SHALL fail, and the failure message SHALL name each drifted file by absolute path with its drift reason and SHALL state the command that regenerates the output

#### Scenario: Comparison target is pinned

- **WHEN** the production codegen configuration is changed so that its output no longer points at the committed generated directory
- **THEN** the generator test suite SHALL fail, so that the drift assertion cannot be silently deprived of its comparison target
