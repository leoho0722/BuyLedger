## ADDED Requirements

### Requirement: Absent data is presented as absent, not as zero

When a calculation cannot be performed because its input data is unavailable, the interface SHALL present an empty state rather than rendering the calculation's layout populated with zero values. Derived amounts SHALL be shown as a placeholder dash, and proportional indicators such as progress bars SHALL NOT be drawn at zero.

#### Scenario: Quote shows an empty state without a usable rate

- **WHEN** the quote screen is presented and no usable exchange rate is available
- **THEN** the suggested price and estimated profit display a placeholder dash, the cost breakdown is replaced by an empty state explaining that the calculation cannot be performed, and no zero-valued progress bars are drawn

#### Scenario: Quote calculates normally when a rate is available

- **WHEN** a usable exchange rate is available
- **THEN** the quote screen renders the suggested price, estimated profit, and cost breakdown as it did before this change

### Requirement: User-facing errors use user vocabulary

An error message shown in the interface SHALL use terms the user can understand and SHALL describe an action the user is able to perform. It SHALL NOT expose build-time identifiers, environment variable names, or other developer-facing details, because the user has no means of acting on them. Diagnostic detail SHALL be routed to logging rather than to the interface.

#### Scenario: AI summary failure hides configuration identifiers

- **WHEN** the AI summary feature fails because its service is not configured
- **THEN** the displayed message describes the situation in user terms and does not name any environment variable or build setting

### Requirement: Initial loading presents a structural skeleton

A screen loading its initial content SHALL present a placeholder skeleton reflecting its actual layout structure, rather than a full-screen indicator over an otherwise blank screen. The skeleton SHALL match the real layout closely enough that no visible jump occurs when content replaces it. A progress indicator SHALL appear only if loading exceeds a short delay.

#### Scenario: Dashboard shows a skeleton while loading

- **WHEN** the dashboard is presented before its content has loaded
- **THEN** a skeleton reflecting the hero card and metric grid structure is shown

#### Scenario: Content replaces the skeleton without layout jump

- **WHEN** loading completes and content replaces the skeleton
- **THEN** the layout does not visibly shift

### Requirement: Failed loads offer a retry path within the screen

A screen whose content fails to load SHALL offer a retry control within the screen itself. Recovery SHALL NOT depend on the user leaving and re-entering the screen, because that requirement is not communicated anywhere in the interface.

#### Scenario: Exchange rate failure offers retry

- **WHEN** exchange rate loading fails and the exchange rate screen is presented
- **THEN** a retry control is available alongside the failure message, and activating it attempts the load again

#### Scenario: Retry restores content on success

- **WHEN** the user activates retry and the load succeeds
- **THEN** the failure message is replaced by the loaded content
