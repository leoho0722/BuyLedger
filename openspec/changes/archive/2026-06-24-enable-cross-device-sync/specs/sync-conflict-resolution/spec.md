## ADDED Requirements

### Requirement: Field-level merge with strict-greater clock acceptance

The backend SHALL merge concurrent edits field-by-field. Each changed field in a patch MUST carry an HLC clock; a patch with a changed field lacking a clock SHALL be rejected with HTTP 400. A field SHALL be accepted if and only if its incoming clock is strictly greater than the stored clock; an equal clock SHALL keep the stored value. Disjoint-field edits from two devices SHALL both survive. Same-field collisions SHALL be resolved deterministically by HLC compare (physical time, then logical counter, then writerId). Co-editable field writes SHALL NOT produce a 409. The backend SHALL recompute the order summary after the merge and SHALL remain the only implementer of financial formulas.

#### Scenario: Disjoint fields auto-merge

- **WHEN** device A changes customerName and device B changes amount on the same order concurrently
- **THEN** both changes SHALL survive in the merged record with no user prompt

##### Example: disjoint vs same-field outcomes

| Device A change | Device B change | Merged result |
| --------------- | --------------- | ------------- |
| customerName="王" @clock 5 | amount="100" @clock 6 | customerName="王", amount="100" |
| amount="100" @clock 5 | amount="200" @clock 6 | amount="200" (higher clock wins) |
| amount="100" @clock 6 | amount="200" @clock 6 | tie broken by writerId, deterministic |

### Requirement: HLC operations are identical across platforms and clamped by the backend

Every platform SHALL implement the HLC generate, receive, and compare operations identically. The receive operation SHALL run on observing any remote HLC (a pulled field, a tombstone, or an API response) before the next local write, advancing the locally issued clock and persisting it so it survives relaunch. The backend SHALL run the receive step for every patch and SHALL act as the linearization point: it SHALL reject or clamp any incoming physical time more than a bounded future tolerance ahead of the injected server clock, and it SHALL re-stamp each winning field with a deterministic server clock so that an identical resend yields the identical stored clock. Physical time SHALL be read only through an injected dependency.

#### Scenario: Skewed offline device does not beat a genuinely newer online edit

- **WHEN** a wall-clock-skewed offline device A stamps a future clock, online device B makes a genuinely later edit to the same field, and A's patch arrives last
- **THEN** the backend receive and clamp steps SHALL ensure B's value survives and all platforms SHALL converge to B

#### Scenario: Patch with an out-of-tolerance future clock is rejected

- **WHEN** a patch carries a physical time more than the bounded tolerance ahead of the server clock
- **THEN** the backend SHALL reject the patch with HTTP 400 or clamp it, and SHALL NOT let the skewed clock win future races

### Requirement: Delete is a clocked tombstone with non-lossy resurrection

A delete SHALL be represented as a clocked tombstone that preserves the full row and all per-field clocks and sets a deleteClock, and the mirror SHALL write an explicit deleted marker rather than document absence. When a concurrent field write carries any field clock strictly greater than the deleteClock, the entity SHALL resurrect by restoring the full prior field set at their stored clocks and overlaying only the changed fields whose clock is strictly greater than the stored field clock, then re-running normalization. When the deleteClock is greater than or equal to every incoming clock, the entity SHALL stay deleted. An equal-clock delete-versus-update SHALL resolve as delete wins. Tombstones SHALL be retained for a bounded window that exceeds the maximum offline edit window before being purged.

#### Scenario: Delete vs concurrent edit resurrects without field loss

- **WHEN** device A deletes an order at deleteClock 1800 while device B edits only amount at clock 2000
- **THEN** the order SHALL resurrect, retaining customerName and note at their stored clocks with amount overlaid, and SHALL NOT become a partial row with missing required fields

#### Scenario: Later delete stays deleted

- **WHEN** the deleteClock is greater than or equal to every incoming field clock
- **THEN** the entity SHALL remain deleted and reads SHALL exclude it
