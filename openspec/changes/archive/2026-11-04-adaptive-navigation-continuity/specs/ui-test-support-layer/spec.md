## MODIFIED Requirements

### Requirement: Layout-agnostic navigation

A navigation helper SHALL expose semantic root navigation operations across native tab and sidebar presentations. It SHALL detect the available root controls at runtime independently from a feature's collapsed or side-by-side presentation. Tests and page objects SHALL use this helper rather than querying root tab bars or sidebars directly. The helper SHALL NOT infer feature column presentation from the existence of a tab bar, root sidebar or device name. Feature presentation checks SHALL inspect that feature's list and detail regions. Failure to identify required navigation controls SHALL fail with diagnostics rather than skip the test.

#### Scenario: The same operation works through tabs and sidebar

- **GIVEN** the root uses tabs in one run and the sidebar in another
- **WHEN** a test asks the navigator to switch to orders
- **THEN** the helper activates the appropriate orders control and waits for that feature to be ready in each run

#### Scenario: Detection needs no declared device kind

- **GIVEN** the same test binary runs on iPhone and iPad
- **WHEN** root presentation changes during the run
- **THEN** the helper finds the current controls without the test declaring a device kind

#### Scenario: Tab navigation does not imply collapsed content

- **GIVEN** root tabs are visible while orders displays its list and detail side by side
- **WHEN** a test asks for root navigation and checks the orders presentation
- **THEN** root navigation uses the tab control and the feature check reports side-by-side orders content

#### Scenario: Missing navigation fails with diagnostics

- **GIVEN** no required root navigation control becomes available within the test's configured wait
- **WHEN** a test requests navigation
- **THEN** the helper records a diagnostic failure rather than returning success or skipping

