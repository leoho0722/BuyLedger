## MODIFIED Requirements

### Requirement: Campaign entity with two-state lifecycle

The system SHALL provide a Campaign entity with a name, an open date, an optional close date, a lifecycle status, an optional settled date, and notes. The status SHALL be exactly one of two values: ongoing ("開團中") and closed ("已收單"). A newly created campaign SHALL have status ongoing and no settled date.

A campaign name SHALL be unique among campaigns. Because orders relate to campaigns by name rather than by identifier, a duplicate name would let one set of orders count toward two campaigns, would let a rename affect the wrong campaign's orders, and would make name-based navigation reach only one of them. Saving SHALL therefore reject a name that already belongs to another campaign, compared after trimming surrounding whitespace and excluding the campaign being edited. The rejection SHALL happen before any write occurs and SHALL state the reason on the form.

Campaigns that already carry duplicate names from before this rule SHALL remain readable and editable. This capability does not detect, merge, or rename existing duplicates, so the aggregation and navigation consequences described above remain possible for pre-existing data. That is a known limitation, not a closed risk.

Deleting a campaign SHALL be understood as removing the campaign together with every trace of it: its record, its name on member orders, and its reminder link. A deletion that removes only the campaign record SHALL NOT be considered complete, because the presented ledger would then show orders attributed to a campaign that no longer exists.

#### Scenario: Create a campaign

- **WHEN** the user creates a campaign with a name and an open date
- **THEN** the campaign is persisted with status ongoing and no settled date

#### Scenario: Duplicate name is rejected before any write

- **WHEN** the user saves a campaign whose trimmed name already belongs to another campaign
- **THEN** the save is rejected, the reason is shown on the form, and the stored campaign count is unchanged

#### Scenario: Editing a campaign keeps its own name

- **WHEN** the user edits an existing campaign without changing its name and saves
- **THEN** the save succeeds, because the uniqueness comparison excludes the campaign being edited

#### Scenario: Pre-existing duplicates remain usable

- **WHEN** two campaigns sharing a name existed before this rule and the user opens and saves either one without renaming it
- **THEN** the save succeeds

#### Scenario: Deletion leaves no attribution behind

- **WHEN** a campaign with member orders is deleted
- **THEN** no order continues to list that campaign's name
