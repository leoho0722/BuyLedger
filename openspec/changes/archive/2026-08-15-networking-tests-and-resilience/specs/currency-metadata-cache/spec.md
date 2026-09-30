## ADDED Requirements

### Requirement: The currency cache is never emptied by an anomalous response

The cached currency list SHALL be replaced only when the refresh yields a non-empty result. An empty result SHALL be treated as an anomalous response: the existing cache SHALL be preserved and the condition SHALL be reported. The cache SHALL NOT be cleared before the replacement content is known to be usable.

The currency list is loaded dynamically and is never hardcoded, so an emptied cache leaves the user with no currency to choose.

#### Scenario: An empty result preserves the existing cache

- **WHEN** a refresh returns a success status but an empty currency list
- **THEN** the previously cached currencies remain intact and the anomaly is reported

#### Scenario: A non-empty result replaces the cache

- **WHEN** a refresh returns a non-empty currency list
- **THEN** the cache is replaced with that list

#### Scenario: A failed refresh preserves the existing cache

- **WHEN** a refresh fails before returning a list
- **THEN** the previously cached currencies remain intact

##### Example: cache outcome by refresh result

| Refresh result | Cache after |
| -------------- | ----------- |
| non-empty list | replaced with the new list |
| empty list | unchanged |
| request failed | unchanged |
