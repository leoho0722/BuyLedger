## ADDED Requirements

### Requirement: Campaign detail unpaid-only view filter persists across navigation

The campaign detail distribution's "unpaid only" view filter (which restricts the distribution list to customers that are not fully received) SHALL be owned by feature state rather than transient view-local state. While the app is running, its value SHALL persist when the user navigates away from a campaign detail and reopens a campaign detail, and SHALL NOT reset to showing all customers on return. Toggling the filter SHALL update feature state through a dedicated action.

#### Scenario: Unpaid-only filter persists across leaving and re-entering detail

- **WHEN** the user enables "unpaid only" on a campaign detail, navigates back to the campaign list, and reopens a campaign detail
- **THEN** the "unpaid only" filter is still enabled
