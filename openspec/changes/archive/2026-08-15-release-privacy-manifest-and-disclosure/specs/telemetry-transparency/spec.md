## ADDED Requirements

### Requirement: A privacy manifest ships with the application

The application SHALL include a privacy manifest declaring every required-reason API it uses together with the reason code, and declaring the data categories collected by the telemetry SDKs it links along with their tracking domains. The manifest SHALL be present in the built product, not merely in the source tree.

#### Scenario: Manifest is present in the built product

- **WHEN** a release build is produced and its contents are inspected
- **THEN** the privacy manifest is present inside the application bundle

#### Scenario: Required-reason API usage is declared

- **WHEN** the manifest is inspected
- **THEN** it declares the user-defaults API category with a reason code, because the application reads and writes user defaults to persist settings

#### Scenario: Declared collection matches the linked SDKs

- **WHEN** the set of linked telemetry SDKs changes
- **THEN** the manifest's declared data categories and tracking domains are updated in the same change

### Requirement: Telemetry configuration reflects actual behaviour

The mechanism used to control telemetry collection SHALL be one that the platform actually honours. A configuration value that the platform ignores SHALL NOT be relied upon or left in place implying an effect it does not have.

Analytics collection on this platform is governed by a key in the application's own information property list and by a runtime setting that persists and overrides it; a value in the services configuration file does not govern it. Performance instrumentation SHALL be configured before the telemetry framework is initialised, because it cannot be changed afterwards.

#### Scenario: Telemetry collection is unconditionally enabled

- **WHEN** the application launches
- **THEN** the runtime setting for each of the three linked SDKs is applied as enabled on every launch, verifiable from the platform's own diagnostic output, and no application setting or state exists that turns it off

#### Scenario: A misleading configuration value is not left in place

- **WHEN** the configuration is inspected
- **THEN** no value remains that appears to disable collection while having no effect on this platform

#### Scenario: Performance instrumentation is configured before initialisation

- **WHEN** the application launches
- **THEN** the performance instrumentation setting is applied before the telemetry framework is initialised

### Requirement: Sending data off device is disclosed where the action is taken

When an action sends the user's data to a third-party service, the screen presenting that action SHALL state, before the action completes, what is sent and where it goes. The disclosure SHALL enumerate the fields actually transmitted and SHALL NOT describe more or fewer than are sent.

#### Scenario: The summary screen discloses the transfer

- **WHEN** the user opens the AI summary sheet
- **THEN** it states that the current list's product details are sent to a third-party cloud service

#### Scenario: The disclosure enumerates the actual fields

- **WHEN** the disclosure is read
- **THEN** it names the fields actually sent, which are the category, product name, quantity, unit price, and currency, and states that customer names are not sent

#### Scenario: Changing the payload requires changing the disclosure

- **WHEN** the set of fields sent to the third-party service changes
- **THEN** the disclosure is updated in the same change, so that it cannot describe a payload that is no longer accurate
