## MODIFIED Requirements

### Requirement: Semantic and system colors are obtained through system APIs

Semantic colors and system palette colors SHALL be obtained through the system color APIs rather than transcribed as literal hexadecimal values. Transcribed values do not track system revisions, do not participate in increased contrast, and do not participate in vibrancy. Once colors are obtained through system APIs, the palette SHALL NOT maintain parallel light and dark branches, because the system resolves appearance automatically.

The palette SHALL be a single set of static semantic color members declared in one design system source file on the shape style type constrained to colors, each named with the `bl` prefix so that it does not collide with the framework's own color members. Call sites SHALL name these members directly wherever a color or a shape style is expected. There SHALL be no palette instance type, no per-view palette accessor, and no parameter that passes a palette from one type to another. A type that aggregates order data for a chart or a list SHALL NOT hold palette colors; it SHALL describe the intended color with a semantic tone that the view converts to a palette color.

The system color APIs SHALL be called from the palette alone. Every other source file SHALL obtain color through the palette or through a design system entry point built on it, so that the palette is the single place where a color enters the app. Any API that constructs a color from raw components (hexadecimal, RGB, or an explicit color space) SHALL NOT exist outside the palette and the one component that generates hues algorithmically.

Named system colors SHALL NOT be used directly in place of their palette counterparts. The sole exceptions are white, black, and clear, which do not resolve per appearance and are not semantic: they express text over a fixed gradient, a scrim, and absence of fill respectively.

Views SHALL NOT declare a dependency on the current appearance in order to obtain a color, because the palette resolves appearance through system dynamic colors and asset catalog resources.

#### Scenario: Palette colors respond to increased contrast

- **WHEN** the user enables the increased contrast setting
- **THEN** semantic colors throughout the app resolve to their increased-contrast counterparts without any app-side branching

#### Scenario: Palette has no appearance branch

- **WHEN** the palette implementation is inspected after this change
- **THEN** it exposes no dark-appearance flag and its color accessors require no appearance parameter

#### Scenario: Call sites name palette colors directly

- **WHEN** a view sets a foreground style, a fill, a background, or a tint from the palette
- **THEN** it names the `bl` member directly, without creating a palette value or receiving one as a parameter

##### Example: call site forms

| Context | Call site |
| ------- | --------- |
| Shape style parameter | `.foregroundStyle(.blLabel)` |
| Conditional style | `.foregroundStyle(isSelected ? .blAccent : .blLabel)` |
| Adjusted opacity | `.fill(.blGreen.opacity(0.14))` |
| Color parameter | `ProgressView(value:)` styled with `BLProgressViewStyle(tint: .blGreen)` |
| No contextual type | `let color = Color.blAccent` |

#### Scenario: No palette instance remains

- **WHEN** the production and test sources are searched for a palette instance type, a per-view palette accessor, or a palette parameter
- **THEN** none is found

#### Scenario: Data types describe colors with tones

- **WHEN** the insights cost structure is computed
- **THEN** each segment carries a semantic tone, and the cost structure card converts the tone to a palette color

##### Example: cost segment tones

| Segment | Tone | Palette color drawn by the card |
| ------- | ---- | ------------------------------- |
| Item cost | accent | `blAccent` |
| Local shipping | teal | `blTeal` |
| International shipping | purple | `blPurple` |
| Fees | orange | `blOrange` |

#### Scenario: System color APIs appear only in the palette

- **WHEN** the sources are searched for calls to the system color APIs
- **THEN** every call is inside the palette

#### Scenario: Named system colors are not used in place of palette colors

- **WHEN** the sources are searched for named system colors such as the system accent, green, or orange
- **THEN** none is found outside white, black, and clear

#### Scenario: Raw color construction does not exist outside its two homes

- **WHEN** the sources are searched for color construction from hexadecimal, RGB, or an explicit color space
- **THEN** no such construction exists outside the palette and the component that generates avatar hues
