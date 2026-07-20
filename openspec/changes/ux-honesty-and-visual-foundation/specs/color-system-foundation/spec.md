## ADDED Requirements

### Requirement: Semantic and system colors are obtained through system APIs

Semantic colors and system palette colors SHALL be obtained through the system color APIs rather than transcribed as literal hexadecimal values. Transcribed values do not track system revisions, do not participate in increased contrast, and do not participate in vibrancy. Once colors are obtained through system APIs, the palette SHALL NOT maintain parallel light and dark branches, because the system resolves appearance automatically.

#### Scenario: Palette colors respond to increased contrast

- **WHEN** the user enables the increased contrast setting
- **THEN** semantic colors throughout the app resolve to their increased-contrast counterparts without any app-side branching

#### Scenario: Palette has no appearance branch

- **WHEN** the palette implementation is inspected after this change
- **THEN** it exposes no dark-appearance flag and its color accessors require no appearance parameter

### Requirement: Accent color has a single source

The app accent color SHALL be defined once as a color resource carrying light, dark, and increased-contrast variants, and SHALL be applied at the root so that system components and custom components resolve the same value. The palette SHALL reference that resource rather than defining an independent value.

#### Scenario: System and custom components match

- **WHEN** a screen presents both a system component and a custom component that use the accent color
- **THEN** both render the same color

#### Scenario: Accent resource defines its variants

- **WHEN** the accent color resource is inspected
- **THEN** it defines light and dark appearances and an increased-contrast variant for each

### Requirement: Visual hierarchy is not expressed by reducing opacity of text

Text hierarchy SHALL be expressed through weight and size rather than by reducing opacity, because reducing opacity lowers contrast against the background. Text drawn over a colored or gradient background SHALL be fully opaque and SHALL meet the 4.5:1 contrast floor against that background; graphic elements drawn over it SHALL meet 3:1.

#### Scenario: Dashboard hero text is fully opaque and legible

- **WHEN** the dashboard hero card renders its label, delta, separator, and progress text
- **THEN** each is fully opaque and reaches at least 4.5:1 against the gradient beneath it

##### Example: measured hero elements before this change

| Element | Opacity applied | Contrast before |
| ------- | --------------- | --------------- |
| Month and net profit label | 0.85 | 3.02:1 |
| Delta and order count | 0.90 | 3.24:1 |
| Separator dot | 0.50 | 2.03:1 |
| Goal progress text | none | 4.02:1 |
| Sparkline stroke | 0.60 | 2.34:1 |

#### Scenario: Gradient meets the floor at both ends

- **WHEN** the hero gradient is evaluated at each of its two endpoint colors
- **THEN** fully opaque white text reaches at least 4.5:1 against both
