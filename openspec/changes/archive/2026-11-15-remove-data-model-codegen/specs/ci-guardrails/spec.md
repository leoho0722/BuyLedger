## MODIFIED Requirements

### Requirement: Repository-level checks are enforced by remote automation

The repository SHALL define a continuous integration workflow that runs on pushes to the default branch, on pull requests, and on manual dispatch. The workflow SHALL enforce iOS unit tests. Enforcement SHALL NOT depend on locally installed git hooks, because a hook can be bypassed per invocation and does not survive a fresh clone.

#### Scenario: Failing unit tests are rejected

- **WHEN** a commit that breaks a unit test is pushed
- **THEN** the iOS unit test job fails and publishes a downloadable test result bundle for diagnosis

#### Scenario: Restoring the change turns the workflow green

- **WHEN** the offending commit is reverted
- **THEN** the same workflow succeeds without further intervention

### Requirement: Simulator-dependent regression stays on manual dispatch

The workflow SHALL NOT run the UI regression suite on ordinary pushes or pull requests. The UI regression job SHALL execute only on manual dispatch, because it requires a booted simulator and has a materially longer runtime than the other jobs.

#### Scenario: Ordinary push does not run UI regression

- **WHEN** a commit is pushed to the default branch
- **THEN** the workflow run contains the iOS unit test job and does not contain the UI regression job

#### Scenario: Manual dispatch runs UI regression

- **WHEN** the workflow is dispatched manually
- **THEN** the UI regression job executes
