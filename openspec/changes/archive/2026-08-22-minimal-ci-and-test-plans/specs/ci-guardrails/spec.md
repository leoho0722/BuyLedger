## ADDED Requirements

### Requirement: Repository-level checks are enforced by remote automation

The repository SHALL define a continuous integration workflow that runs on pushes to the default branch, on pull requests, and on manual dispatch. The workflow SHALL enforce data model drift detection, generator tests, and iOS unit tests. Enforcement SHALL NOT depend on locally installed git hooks, because a hook can be bypassed per invocation and does not survive a fresh clone.

#### Scenario: Drift reaches the remote and is rejected

- **WHEN** a commit changes the schema directory without regenerating the committed output and is pushed
- **THEN** the codegen job fails and the failing step is the drift check or the generator test suite

#### Scenario: Failing unit tests are rejected

- **WHEN** a commit that breaks a unit test is pushed
- **THEN** the iOS unit test job fails and publishes a downloadable test result bundle for diagnosis

#### Scenario: Restoring the change turns the workflow green

- **WHEN** the offending commit is reverted or the output is regenerated
- **THEN** the same workflow succeeds without further intervention

### Requirement: Simulator-dependent regression stays on manual dispatch

The workflow SHALL NOT run the UI regression suite on ordinary pushes or pull requests. The UI regression job SHALL execute only on manual dispatch, because it requires a booted simulator and has a materially longer runtime than the other jobs.

#### Scenario: Ordinary push does not run UI regression

- **WHEN** a commit is pushed to the default branch
- **THEN** the workflow run contains the codegen and iOS unit test jobs and does not contain the UI regression job

#### Scenario: Manual dispatch runs UI regression

- **WHEN** the workflow is dispatched manually
- **THEN** the UI regression job executes

### Requirement: Continuous integration requires no repository secrets

The workflow SHALL complete without any repository secret. Configuration files that are excluded from version control SHALL be reconstructed in continuous integration from committed template files whose values are obvious placeholders and contain no real credentials or project identifiers. Template files SHALL be excluded from the application bundle.

#### Scenario: Fresh clone builds the test host

- **WHEN** the workflow checks out the repository and copies the committed templates into the expected configuration file names
- **THEN** the test host application launches and the unit test suite runs to completion

#### Scenario: Templates never ship

- **WHEN** the application is built
- **THEN** the produced application bundle does not contain any template configuration file

#### Scenario: Real configuration is never committed

- **WHEN** the working tree is inspected after a build
- **THEN** no ignored real configuration file appears as an untracked or modified change

### Requirement: Continuous integration uses the project build CLI and resolves simulators dynamically

The workflow SHALL drive builds and tests through the project's designated build CLI at a pinned version, and SHALL NOT invoke the native Xcode command line tools directly. The workflow SHALL resolve the simulator by querying available simulators and passing an identifier, and SHALL NOT hardcode a simulator name. When no simulator matching the required runtime version is available, the job SHALL fail explicitly.

#### Scenario: Native tooling is not used

- **WHEN** the workflow definition is inspected
- **THEN** it contains no direct invocation of the native Xcode build, run, or simulator control commands

#### Scenario: Simulator resolved by identifier

- **WHEN** the iOS job prepares to run tests
- **THEN** it queries the available simulators, selects one matching the required runtime version, and passes its identifier to the test command

#### Scenario: Missing runtime fails loudly

- **WHEN** no simulator matching the required runtime version exists on the runner
- **THEN** the job fails with an explicit message rather than falling back to an older runtime

### Requirement: Unstable suites are excluded until continuous integration is trusted

The first iteration of the iOS job SHALL exclude the snapshot suite and the performance suite, because both have documented environment-sensitive failure modes unrelated to the code under test. Exclusions SHALL be explicit in the workflow rather than implicit, so that what is not covered is visible.

#### Scenario: Snapshot and performance suites are skipped by name

- **WHEN** the iOS unit test job runs
- **THEN** the snapshot suite and the performance suite are excluded by explicit skip arguments

#### Scenario: Remaining suites still gate

- **WHEN** a non-excluded unit test fails
- **THEN** the job fails

### Requirement: Test plans pin locale and expose coverage

Every test scheme SHALL execute under a test plan that pins language and region, so that results do not depend on the simulator's current system state. Test plans SHALL enable code coverage scoped to the application target only. No coverage threshold SHALL be enforced.

#### Scenario: Locale no longer follows the simulator

- **WHEN** unit tests run through the main scheme
- **THEN** the language and region come from the test plan, and snapshots containing locale-sensitive date formatting are unaffected by the simulator's system language

#### Scenario: Coverage is queryable

- **WHEN** a test run completes
- **THEN** the coverage figure for the application target can be read from the produced result bundle

#### Scenario: Coverage does not gate

- **WHEN** the coverage figure falls
- **THEN** no job fails as a result, because coverage is collected for blind-spot analysis rather than enforcement
