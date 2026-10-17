## MODIFIED Requirements

### Requirement: Semantic and system colors are obtained through system APIs

Semantic colors and system palette colors SHALL be obtained through the system color APIs rather than transcribed as literal hexadecimal values. Transcribed values do not track system revisions, do not participate in increased contrast, and do not participate in vibrancy. Once colors are obtained through system APIs, the palette SHALL NOT maintain parallel light and dark branches, because the system resolves appearance automatically.

The system color APIs SHALL be called from the palette alone. Every other source file SHALL obtain color through the palette or through a design system entry point built on it, so that the palette is the single place where a color enters the app. Any API that constructs a color from raw components (hexadecimal, RGB, or an explicit color space) SHALL NOT exist outside the palette and the one component that generates hues algorithmically.

Named system colors SHALL NOT be used directly in place of their palette counterparts. The sole exceptions are white, black, and clear, which do not resolve per appearance and are not semantic: they express text over a fixed gradient, a scrim, and absence of fill respectively.

Views SHALL NOT declare a dependency on the current appearance in order to obtain a color, because the palette resolves appearance through system dynamic colors and asset catalog resources.

#### Scenario: Palette colors respond to increased contrast

- **WHEN** the user enables the increased contrast setting
- **THEN** semantic colors throughout the app resolve to their increased-contrast counterparts without any app-side branching

#### Scenario: Palette has no appearance branch

- **WHEN** the palette implementation is inspected after this change
- **THEN** it exposes no dark-appearance flag and its color accessors require no appearance parameter

#### Scenario: System color APIs appear only in the palette

- **WHEN** the sources are searched for calls to the system color APIs
- **THEN** every call is inside the palette

#### Scenario: Named system colors are not used in place of palette colors

- **WHEN** the sources are searched for named system colors such as the system accent, green, or orange
- **THEN** none is found outside white, black, and clear

#### Scenario: Raw color construction does not exist outside its two homes

- **WHEN** the sources are searched for color construction from hexadecimal, RGB, or an explicit color space
- **THEN** no such construction exists outside the palette and the component that generates avatar hues
