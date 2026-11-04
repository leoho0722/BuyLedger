## MODIFIED Requirements

### Requirement: Each destination is reachable through a single path

A destination SHALL be reachable through one canonical navigation path so that back navigation reflects its hierarchy. List selection, cross-feature navigation and deep links SHALL write through the same feature-owned navigation operation. Opening the currently selected destination again SHALL preserve its existing state and identity without adding a copy. Opening a different sibling destination SHALL replace the current root detail or tool in one state update, without presenting both copies or leaving an unrelated sibling in the back path. Nested navigation belonging to the selected destination SHALL retain its own hierarchy.

#### Scenario: Deep link does not stack a second copy

- **GIVEN** settings is already open from the More list with current local state
- **WHEN** a deep link opens settings again
- **THEN** exactly one settings destination exists with its existing state preserved
- **AND** navigating back once returns to the More list

#### Scenario: Back path reflects the true hierarchy

- **GIVEN** a tool is selected in More
- **WHEN** settings is opened through another available entry
- **THEN** settings replaces the sibling tool as the root destination
- **AND** back navigation returns to the More list rather than that sibling

### Requirement: Selection has a single source of truth

A list's current navigation selection SHALL have one source of truth. Its row highlight and displayed destination SHALL derive from the same feature-owned destination identity, including collapsed and side-by-side presentations. Independent selected-detail states SHALL NOT coexist for different sizes. Root destination selection SHALL likewise highlight exactly one destination. Batch-operation selection SHALL remain a separate set of targets and SHALL NOT become a second current-detail identity.

#### Scenario: Sidebar highlights exactly one row

- **GIVEN** campaigns is selected in the root sidebar
- **WHEN** the user selects orders
- **THEN** only the orders root row is highlighted

#### Scenario: Campaign row highlight follows the current destination

- **GIVEN** the campaigns feature shows the list and detail side by side without keyboard focus
- **WHEN** the user selects the campaign `四月韓國團`
- **THEN** only that campaign row shows the selected background and the detail column shows `四月韓國團`
- **AND** unselected campaign rows keep their original appearance

#### Scenario: The same order survives both directions of a resize

- **GIVEN** order `BL-2604-017` is opened in collapsed navigation
- **WHEN** the user expands the window, selects `BL-2604-015`, then collapses the window
- **THEN** the final detail and row-selection state identify only `BL-2604-015`
- **AND** no independent expanded-detail state restores `BL-2604-017`

#### Scenario: Batch targets do not change the current detail

- **GIVEN** order `BL-2604-017` is the current detail
- **WHEN** the user adds other orders to the batch-selection set
- **THEN** those batch targets are represented independently and the current detail remains `BL-2604-017`

### Requirement: The sidebar lists destinations only

When the system adaptive root sidebar is displayed, it SHALL list dashboard, orders, campaigns, insights and more without order-status shortcuts. Status-specific orders SHALL remain reachable through the orders list's status filter. The orders destination SHALL retain its active-order count badge. The same destination identities SHALL be used in root tabs and the sidebar.

#### Scenario: Root sidebar lists destinations without status shortcuts

- **GIVEN** the root is displayed as tabs
- **WHEN** the user switches to the sidebar
- **THEN** the five destinations and the orders active-count badge are available
- **AND** no order-status shortcut section appears

## ADDED Requirements

### Requirement: Navigation state survives presentation and tab changes

Within a live scene, changing root tabs, root bar presentation, orientation, window size or fold pose SHALL preserve each feature's current destination, search and filters, batch targets, detail-local state and unsaved drafts. Returning to a tab SHALL restore its current destination adapted to the available space. A source page delegating navigation to another feature SHALL retain its own state. User-initiated back navigation SHALL clear the current root destination when it returns to that feature's list; presentation-only callbacks SHALL NOT be interpreted as user back navigation. State restoration across app relaunch or separate scenes is outside this requirement.

#### Scenario: More settings survives a round trip through orders

- **GIVEN** settings is open in More on iPad
- **WHEN** the user switches to orders and then back to More, including a root sidebar change between switches
- **THEN** settings remains the current More destination with its state retained
- **AND** navigation completes without an assertion failure or crash

#### Scenario: Cross-feature navigation keeps the source tool

- **GIVEN** the customer list is open in More
- **WHEN** the user opens that customer's orders and later returns to More
- **THEN** the customer list remains available in its previous state
- **AND** orders applies the selected customer name as search text through its existing canonical navigation operation

#### Scenario: Campaign detail retains its local filter

- **GIVEN** a campaign detail has its unpaid-only filter enabled
- **WHEN** the user resizes the window, visits another tab and returns
- **THEN** the same campaign detail retains the unpaid-only filter

#### Scenario: Explicit back differs from automatic collapse

- **GIVEN** a detail is selected in orders, campaigns or More
- **WHEN** the window collapses and the user then explicitly navigates back to the list before expanding again
- **THEN** the expanded detail shows the selection prompt
- **AND** collapse alone, without that back operation, retains the original destination

### Requirement: Lists do not implicitly open their first destination

Orders, campaigns and More SHALL begin without a selected destination. Initial loading, retrying, refreshing data and resizing SHALL NOT choose the first entry. A list selection or explicit navigation intent SHALL open a destination. Without a selection, expanded navigation SHALL show a localized selection prompt and collapsed navigation SHALL show the list. Removing the selected order or campaign from the underlying data SHALL clear the invalid destination instead of displaying stale data or choosing its neighbor. Saving new content SHALL NOT implicitly open the first list entry; an explicit navigation intent associated with a save SHALL retain its stated target.

#### Scenario: Loading and retrying do not select the first row

- **GIVEN** a feature has no selected destination
- **WHEN** its first data load succeeds, or a failed load is retried successfully
- **THEN** no row becomes the current destination
- **AND** the expanded presentation shows its prompt while the collapsed presentation shows its list

#### Scenario: Refresh preserves a valid destination

- **GIVEN** order `BL-2604-017` is selected and remains valid in the loaded data
- **WHEN** a refresh changes the first row to a different order
- **THEN** `BL-2604-017` remains selected with its detail-local state intact

#### Scenario: Deletion invalidates the destination without replacement

- **GIVEN** an order or campaign is selected
- **WHEN** that entity is deleted, or the selected order ID disappears after a merge
- **THEN** its destination is cleared
- **AND** no remaining entry is selected automatically

### Requirement: Order filtering preserves only a matching destination

After an order search, filter update or date context refresh, the orders feature SHALL retain its current destination and detail state if that order remains in the resulting list. If it is excluded, the feature SHALL clear the destination without selecting a replacement. This rule SHALL apply to the existing search, status, date, category and payment filters and to clearing filters. Cross-feature customer navigation SHALL set the existing search text and follow the same result-based selection rule; it SHALL NOT introduce a separate customer or campaign filter. A filter update with no current destination SHALL leave it unselected. The list and destination validity SHALL use the same filtered result. As a recorded exception, a date context update made by the list itself when it appears or retries SHALL NOT evaluate the current destination; an order excluded only by that update MAY remain until the next search or filter update.

#### Scenario: Customer navigation uses the existing search result

- **GIVEN** an order for Mika is the current destination
- **WHEN** the customer list delegates navigation to Joyce
- **THEN** the existing orders search text becomes `Joyce` through the shared navigation operation
- **AND** the previous destination is retained only if it matches that resulting search; otherwise it is cleared without selecting the first result

#### Scenario: Filtering retains or clears the current order deterministically

- **GIVEN** `BL-2604-017` belongs to Mika and is the current order
- **WHEN** search is changed to `Mika`, then to a query excluding that order, then cleared
- **THEN** the first update retains the existing detail state, the second clears it and the third leaves no selection

#### Scenario: Regular detail column clears when search excludes the shown order

- **GIVEN** the orders feature shows the list and detail side by side with `UITEST-MRG-001` open in the detail column
- **WHEN** the user types `ZZZ-NO-SUCH-ORDER` into the orders search field so that no order matches
- **THEN** the detail column shows the empty selection prompt instead of `UITEST-MRG-001`
- **AND** the list selection binding does not restore `UITEST-MRG-001` while the search still excludes it

#### Scenario: Date context refresh clears an order excluded by a date filter

- **GIVEN** the `this month` date filter is applied and `BL-2604-017` dated 2026-04-24 is the current order
- **WHEN** the app returns to the foreground or the system reports a significant time change and the date context is refreshed
- **THEN** the current order is retained if the refreshed period still includes it and cleared otherwise without selecting another order
- **AND** a customer or category deep link applies its new filter before checking the current order
- **AND** an order already excluded before the refresh, such as after its status changed outside the filter, is not cleared by the refresh

##### Example: current order after a date context refresh

| Date filter | Current destination | Refreshed date | Result |
| --- | --- | --- | --- |
| this month | BL-2604-017 (2026-04-24) | 2026-04-30 | Retain BL-2604-017 and its detail state |
| this month | BL-2604-017 (2026-04-24) | 2026-05-01 | Clear destination |
| all time | BL-2604-017 (2026-04-24) | 2026-05-01 | Retain BL-2604-017 and its detail state |

#### Scenario: A list-initiated date update waits for the next filter update

- **GIVEN** the `this month` date filter is applied, `BL-2604-017` dated 2026-04-24 is the current order and the list has already updated its own date context to 2026-05-01
- **WHEN** the root then refreshes the date context
- **THEN** the current order is retained because it was already excluded before that refresh
- **AND** the next search or filter update checks it again and clears it without selecting another order only if it is still excluded

##### Example: selection after a filter update

| Current destination | Filtered IDs | Result |
| --- | --- | --- |
| BL-2604-017 | BL-2604-015, BL-2604-017 | Retain BL-2604-017 and its detail state |
| BL-2604-017 | BL-2604-015 | Clear destination |
| BL-2604-017 | empty | Clear destination |
| none | BL-2604-015, BL-2604-017 | Remain unselected |

### Requirement: Editing remains continuous during layout adaptation

An existing form or tool SHALL retain its draft, focused field identity and unsaved-change protection during resizing, rotation and folding. Continued typing after the transition SHALL update the same field. Layout adaptation SHALL NOT duplicate a sheet, replace it with another modal, commit a draft or discard edits. The app SHALL respect a keyboard dismissal initiated by the user instead of reopening the keyboard solely to restore presentation.

#### Scenario: Order input survives folding

- **GIVEN** a new-order form contains `DuoDraft` in the focused text field
- **WHEN** the user unfolds the device and types `-continued`
- **THEN** the same field contains `DuoDraft-continued`
- **AND** exactly one form remains presented with unsaved-change protection intact

#### Scenario: Tool and edit drafts survive resizing

- **GIVEN** an unsaved campaign edit, quote input or lookup edit is active in separate runs
- **WHEN** each window is resized and the user continues editing
- **THEN** each run retains its draft and field identity without creating another modal

#### Scenario: A dismissed keyboard stays dismissed

- **GIVEN** the user has explicitly dismissed a form's keyboard
- **WHEN** the device changes orientation
- **THEN** the draft is retained without the app forcing the keyboard open
