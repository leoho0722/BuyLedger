## MODIFIED Requirements

### Requirement: Controls are not placed where the window edge can hide them

Controls and essential information SHALL remain visible and operable within their owning container's safe interactive region as system bars and reserved regions change. The app SHALL respect independent insets on each side rather than assuming a fixed side or fixed reserved width. Batch controls SHALL use system navigation placements accessible when a draggable window's lower edge leaves the screen, rather than a custom bottom bar. A selected-order count SHALL appear once in the list navigation title when collapsed or below search in the side-by-side orders list. Lists SHALL retain ownership of list actions and details SHALL retain ownership of entity actions.

Toolbars SHALL use native placements and grouping, with meaningful text labels and symbols for named actions. On systems supporting adaptive overflow, suitable secondary toolbar actions SHALL remain reachable through that overflow; older supported systems SHALL retain equivalent access through their native menus. Status selection SHALL retain a named status menu. Horizontal filter chips SHALL keep both rendering and hit testing within the safe content region as system bars move. The app SHALL NOT encode a device-specific fixed inset to avoid a bar.

#### Scenario: Batch operations remain reachable when the window is dragged

- **GIVEN** the orders list is in multi-select mode on iPad
- **WHEN** the user drags the window so its lower edge extends beyond the screen
- **THEN** batch actions and the selection count remain visible and usable

#### Scenario: Selection count belongs to the current list presentation

- **GIVEN** orders are selected for batch operations
- **WHEN** the list changes between collapsed and side-by-side presentation
- **THEN** the count appears once in the collapsed navigation title or at the top of the expanded list below search respectively
- **AND** it does not migrate into the detail toolbar

#### Scenario: Moving system bars does not cover filter controls

- **GIVEN** order status chips are horizontally scrollable on Duo
- **WHEN** orientation or window placement moves a reserved system region to either side
- **THEN** chip content and hit targets remain inside the current safe content region
- **AND** the user can scroll to and activate every filter chip without tapping a system control

#### Scenario: Toolbar actions remain available across supported systems

- **GIVEN** an orders list or order detail is open
- **WHEN** its toolbar adapts to a narrow or side placement
- **THEN** its primary and secondary actions retain meaningful accessible names and reachable native controls
- **AND** equivalent actions remain available on iOS 26 without requiring a newer toolbar API

### Requirement: System back navigation is preserved

A pushed screen SHALL retain the system back button and interactive pop gesture. A collapsed split-navigation detail SHALL provide the system return path to its list. The app SHALL NOT hide system back navigation and replace it with a custom control. The back path SHALL follow the current feature's hierarchy, and localized back labels SHALL reflect the current app language. Automatic column collapse or expansion SHALL NOT itself perform a user back action or discard the destination.

#### Scenario: Settings supports edge swipe back

- **GIVEN** settings is open in collapsed More navigation
- **WHEN** the user swipes from the leading screen edge
- **THEN** settings returns to the More list through system navigation

#### Scenario: Back button does not show a stale title

- **GIVEN** the in-app language has changed
- **WHEN** the user navigates to settings
- **THEN** the system back label reflects the current language rather than a cached previous title

#### Scenario: Split collapse preserves a native return path

- **GIVEN** an order or campaign is selected in side-by-side navigation
- **WHEN** the window narrows until navigation collapses
- **THEN** the same detail remains presented with its native return path
- **AND** using that return path clears its current root destination and shows the list
