## ADDED Requirements

### Requirement: One setting controls both locking and authentication

The settings screen SHALL provide a single control that turns ledger protection on or off. While on, the app SHALL replace its visible content with a lock screen whenever it enters the background, and SHALL require authentication before revealing content when it returns to the foreground or launches. While off, the app SHALL behave exactly as it did before this capability existed, with no locking and no authentication.

Splitting these into separate controls SHALL NOT be done: locking without authentication lets anyone dismiss the lock screen without proving identity, and authentication without locking leaves content visible on screen until the app happens to launch again, so neither half is meaningful alone.

This capability locks content by replacing it with a lock screen; it does not present a separate window-level obscuring layer, and it does not guarantee that the operating system's multitasking snapshot excludes content captured before the lock screen takes over.

#### Scenario: Protection on locks and authenticates

- **WHEN** protection is on and the user leaves the app and returns
- **THEN** the content was replaced with a lock screen while away and authentication is required before it is revealed

#### Scenario: Protection off changes nothing

- **WHEN** protection is off
- **THEN** the app neither locks its content nor requires authentication at any point

#### Scenario: The setting persists across launches

- **WHEN** protection is on and the app is terminated and launched again
- **THEN** protection is still on and authentication is required before content is revealed

### Requirement: Enabling protection requires passing authentication first

Turning protection on SHALL require a successful authentication at the moment of turning it on. When authentication fails, is cancelled, or biometric authentication is unavailable on the device, protection SHALL remain off and the reason SHALL be stated in a dialog.

This prevents the state in which a user enables protection and is then unable to get back in, which the user cannot resolve from inside the app.

#### Scenario: Successful authentication enables protection

- **WHEN** the user turns the control on and authentication succeeds
- **THEN** protection becomes active and the setting is stored

#### Scenario: Failed authentication leaves protection off

- **WHEN** the user turns the control on and authentication fails or is cancelled
- **THEN** protection remains off, the control returns to its off position, and a dialog states why

#### Scenario: Unsupported device cannot enable protection

- **WHEN** the device does not support biometric authentication and the user turns the control on
- **THEN** protection remains off and a dialog states that the device does not support it

### Requirement: Authentication is delegated to the system

The app SHALL use the platform's local authentication mechanism and SHALL NOT implement its own passcode or PIN flow. The app SHALL NOT store any authentication secret. The system's own fallback from biometric to device passcode SHALL be used rather than reimplemented.

#### Scenario: No app-defined secret exists

- **WHEN** the codebase is inspected for authentication handling
- **THEN** no passcode or PIN entry flow and no stored authentication secret exists

#### Scenario: Biometric failure falls back through the system

- **WHEN** biometric authentication fails and the system offers device passcode entry
- **THEN** that system fallback is used and a successful entry reveals the content

### Requirement: The unlock prompt names the device's biometric method

The lock screen's unlock control and the settings screen's protection control SHALL both name the specific biometric method the device supports (Face ID or Touch ID) rather than a generic label, so the wording matches what the device is actually capable of. When the device has no biometric hardware available, a neutral label SHALL be shown instead of an empty or malformed string; enabling protection through the device passcode alone remains possible, so this fallback is a real, reachable state and not a theoretical one.

The settings screen's naming does not depend on whether protection is currently turned on: the device's biometric method is a fixed hardware property, not a consequence of the setting, so the wording is correct both before and after the user turns protection on.

#### Scenario: Device supports Face ID

- **WHEN** the lock screen is shown on a device whose available biometric method is Face ID
- **THEN** the unlock control's label names Face ID

#### Scenario: Device supports Touch ID

- **WHEN** the lock screen is shown on a device whose available biometric method is Touch ID
- **THEN** the unlock control's label names Touch ID

#### Scenario: No biometric hardware available

- **WHEN** the lock screen is shown on a device with no biometric hardware available
- **THEN** the unlock control shows a neutral label that names no specific biometric method

#### Scenario: Settings screen names Face ID

- **WHEN** the settings screen's protection control is shown on a device whose available biometric method is Face ID
- **THEN** the control's toggle label and description both name Face ID, whether or not protection is currently turned on

#### Scenario: Settings screen names Touch ID

- **WHEN** the settings screen's protection control is shown on a device whose available biometric method is Touch ID
- **THEN** the control's toggle label and description both name Touch ID, whether or not protection is currently turned on

#### Scenario: Settings screen falls back to a neutral label

- **WHEN** the settings screen's protection control is shown on a device with no biometric hardware available
- **THEN** the control's toggle label and description show a neutral wording that names no specific biometric method
