## ADDED Requirements

### Requirement: Persistence bootstrap failure preserves existing store files

When the app-level persistence bootstrap fails to open the on-disk store, it SHALL NOT delete, truncate, overwrite, or relocate any existing store file, including the write-ahead log and shared-memory sidecars and any legacy store file. The bootstrap SHALL fall back to an in-memory container and SHALL mark the launch outcome as degraded.

#### Scenario: Unmigratable store is left untouched

- **WHEN** the persistence bootstrap runs against an on-disk store whose schema version is below the migration floor
- **THEN** container initialization fails, the bootstrap reports a degraded outcome, and every pre-existing store file remains at its original path with byte-identical contents

#### Scenario: No backup directory is created automatically

- **WHEN** the persistence bootstrap reports a degraded outcome
- **THEN** no quarantine directory exists in the application support directory

#### Scenario: Successful open is unaffected

- **WHEN** the persistence bootstrap opens the on-disk store successfully
- **THEN** the launch outcome is healthy and the resolved container is the on-disk container

### Requirement: A single production container is resolved once per process

The app-level persistence bootstrap SHALL be resolved exactly once per process, and all repositories SHALL obtain their container from that single resolution. The factory that constructs the production container SHALL NOT be reachable from outside the persistence bootstrap.

#### Scenario: Repeated access returns the same container

- **WHEN** the shared container is accessed more than once during a process lifetime
- **THEN** every access returns the same container instance

#### Scenario: Repositories do not construct their own production container

- **WHEN** a repository needs a container
- **THEN** it obtains the shared container rather than invoking the production container factory

### Requirement: Degraded launch blocks the normal interface

When the launch outcome is degraded, the app SHALL present a full-screen failure state and SHALL NOT render the normal navigation surfaces. The failure state SHALL state that the data cannot be opened, that the original data remains intact on the device, and that the user must not add or modify data.

#### Scenario: Degraded launch shows only the failure screen

- **WHEN** the app launches with a degraded outcome
- **THEN** the failure screen is the only content rendered and no tab bar or sidebar navigation element is present

#### Scenario: Healthy launch is never blocked

- **WHEN** the app launches with a healthy outcome
- **THEN** the failure screen is absent and the normal interface renders

#### Scenario: Failure state is decided before first render

- **WHEN** the app launches with a degraded outcome
- **THEN** the failure screen is the first content presented, without an intermediate frame showing the normal interface

### Requirement: Store quarantine requires explicit confirmation and moves rather than deletes

The app SHALL offer a recovery action that relocates the unopenable store files to an isolated backup directory. The action SHALL require an explicit confirmation step before any file is touched, and SHALL relocate files by moving them. It SHALL NOT delete any file. After a successful relocation the app SHALL instruct the user to close and reopen the app.

#### Scenario: Activating the action only asks for confirmation

- **WHEN** the user activates the recovery action on the failure screen
- **THEN** a confirmation prompt appears and no file on disk has changed

#### Scenario: Confirmed quarantine relocates the store files

- **WHEN** the user confirms the recovery action
- **THEN** the store file and its sidecars are moved out of their original location into a backup directory with unchanged contents, and the screen instructs the user to relaunch the app

#### Scenario: Quarantine failure keeps the blocking state

- **WHEN** the relocation fails
- **THEN** the app remains in the blocking failure state and displays the reason for the failure

#### Scenario: Backup directories are allocated by increasing index

- **WHEN** a quarantine is performed
- **THEN** the backup directory name uses the lowest positive integer index not already present

##### Example: index allocation

| Existing backup directories | Resulting directory |
| --------------------------- | ------------------- |
| none | Recovered-1 |
| Recovered-1 | Recovered-2 |
| Recovered-1, Recovered-2 | Recovered-3 |

#### Scenario: Nothing to quarantine

- **WHEN** a quarantine is requested and no store file is present in the source directory
- **THEN** the operation reports that nothing was relocated and creates no directory

### Requirement: Persistence bootstrap failure is recorded as a fault-level diagnostic

The app SHALL record persistence bootstrap failures through the unified logging system at fault level, with the error description marked as publicly readable so it survives in release builds. Diagnostic messages SHALL NOT contain order, customer, or other user-entered content. Crash-reporting upload SHALL be performed through an injectable client and SHALL occur only after crash reporting has been configured.

#### Scenario: Failure is readable in a release build

- **WHEN** the persistence bootstrap fails on a release build
- **THEN** a fault-level log entry is emitted whose error description is readable rather than redacted

#### Scenario: Diagnostics are not uploaded before crash reporting is configured

- **WHEN** the persistence bootstrap fails during app initialization
- **THEN** no crash-reporting call is made until the launch configuration step has configured crash reporting

#### Scenario: Diagnostic upload is injectable

- **WHEN** tests exercise the failure path
- **THEN** the crash-diagnostics client is replaced with a no-op implementation and no external service is contacted
