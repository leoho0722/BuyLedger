## ADDED Requirements

### Requirement: Semantic and system colors are obtained through system APIs

Semantic colors and system palette colors SHALL be obtained through the system color APIs rather than transcribed as literal hexadecimal values. Transcribed values do not track system revisions, do not participate in increased contrast, and do not participate in vibrancy. Once colors are obtained through system APIs, the palette SHALL NOT maintain parallel light and dark branches, because the system resolves appearance automatically.

#### Scenario: Palette colors respond to increased contrast

- **WHEN** the user enables the increased contrast setting
- **THEN** semantic colors throughout the app resolve to their increased-contrast counterparts without any app-side branching

#### Scenario: Palette has no appearance branch

- **WHEN** the palette implementation is inspected after this change
- **THEN** it exposes no dark-appearance flag and its color accessors require no appearance parameter

### Requirement: The app does not force a global tint

The app SHALL NOT apply an explicit global tint and SHALL leave the accent color resource without color values, so system components keep the platform's default accent behavior. Custom components that need an accent visual SHALL take it from the palette, which resolves to the system dynamic blue rather than a hand-copied value.

#### Scenario: System components keep the default accent behavior

- **WHEN** any screen presents system components
- **THEN** their accent rendering follows the platform default, with no app-imposed tint

#### Scenario: Custom components take accent from the palette

- **WHEN** a custom component renders an accent visual
- **THEN** the color comes from the palette's system dynamic blue, which adapts to appearance and increased contrast automatically

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
