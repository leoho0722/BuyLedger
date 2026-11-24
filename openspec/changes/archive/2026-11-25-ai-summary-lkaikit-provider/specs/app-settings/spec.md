## MODIFIED Requirements

### Requirement: A setting that was never written reads as its documented default

When a preference has never been written, reading it SHALL yield the default documented for that preference, not the storage layer's zero value. A value the user has written SHALL be read back as written, including a value that equals the storage layer's zero value. The AI summary model is the exception: when the user's chosen model equals the provider's default model, it SHALL be stored as following the default and SHALL read back as the provider's current default model, as specified in ai-order-summary.

#### Scenario: A fresh install reads the documented monthly goal

- **WHEN** the monthly net profit goal has never been written and the settings are read
- **THEN** the goal is the documented default, so the dashboard shows its goal progress

##### Example: monthly goal reads

| Stored monthly goal | Read value | Notes |
| ------------------- | ---------- | ----- |
| never written | 80,000 | documented default |
| 0 | 0 | user chose no goal |
| 120,000 | 120,000 | user value |

#### Scenario: A deliberately cleared goal stays cleared

- **WHEN** the user has set the monthly net profit goal to zero and the settings are read
- **THEN** the goal is zero, and the dashboard shows no goal progress

#### Scenario: A model equal to the provider default follows the default

- **WHEN** the user saves the provider's default model and the provider's default model later changes
- **THEN** the AI summary model reads as the provider's new default model instead of the previously saved name

### Requirement: Stored preference keys survive code renames

The key under which each preference is stored SHALL remain unchanged when the code identifiers that hold the preference are renamed. A value written by an earlier version SHALL be read by a later version without migration, except that the AI summary model is read only together with the AI summary provider it was saved with, as specified in ai-order-summary; a model stored without a provider reads as the default provider's default model.

#### Scenario: Values written under the existing keys are read after a rename

- **WHEN** every preference is written under the keys used before the identifier renames and the settings are read by the renamed code
- **THEN** every preference reads back the written value

##### Example: the stored keys that stay fixed

| Preference | Stored key |
| ---------- | ---------- |
| interface language | `settings.language` |
| default order currency | `settings.defaultCurrency` |
| monthly net profit goal | `settings.monthlyProfitGoalTwd` |
| AI summary toggle | `settings.useAiSummary` |
| AI summary provider | `settings.aiSummaryProvider` |
| AI summary model | `settings.aiSummaryModel` |
| app lock toggle | `settings.isBiometricUnlockEnabled` |

#### Scenario: A model stored without a provider is not read back

- **WHEN** a model name is stored under `settings.aiSummaryModel` and nothing is stored under `settings.aiSummaryProvider`, and the settings are read
- **THEN** the AI summary model reads as the default provider's default model instead of the stored name
