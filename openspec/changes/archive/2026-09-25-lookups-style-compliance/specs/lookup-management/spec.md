## MODIFIED Requirements

### Requirement: Lookup item management operations are preserved across platforms

The screen SHALL allow the user to add, rename, and delete lookup items on iOS and iPadOS. The add, rename, and delete operations and their validation SHALL behave identically on both, and SHALL write through the same management feature as before this change.

Each operation SHALL update the shared lookup store, and therefore every list derived from it (the management list and the order editor's selectable values), as part of the same state update, rather than through separate synchronization performed by the root feature. Rewriting the orders held in memory after a rename is not part of that update; it follows the requirement "Lookup data has a single source shared by every consumer". Every operation SHALL be written to the store first, and the shared lookup state SHALL change only after that write succeeds; a failed write SHALL leave the shared lookup state exactly as it was before the operation, so that no consumer can select a value the store does not hold.

A failed add, rename, or delete SHALL be reported as a one-time notice that the user dismisses and that disappears once dismissed. A failed payment method correction, whether sampling the affected orders or the atomic write fails, SHALL be reported the same way, and SHALL leave both the payment method and the orders unchanged. It SHALL NOT be written to the load-failure message shown above the list, which is reserved for the screen's initial load failing.

When a lookup management screen cannot be resolved for a requested kind, the screen SHALL present the existing load-failure view rather than rendering blank, so that a resolution failure is visible rather than silent.

#### Scenario: Add a lookup item

- **WHEN** the user activates the toolbar add control and confirms a non-empty, trimmed name, and the write succeeds
- **THEN** the item is added through the management feature and appears in the list

#### Scenario: Rename a lookup item

- **WHEN** the user triggers rename on an item and confirms a non-empty name different from the original, and the write succeeds
- **THEN** the item is renamed through the management feature and orders referencing the old name are updated

#### Scenario: Delete a lookup item

- **WHEN** the user triggers delete on an item, confirms, and the write succeeds
- **THEN** the item is removed through the management feature

#### Scenario: A failed operation leaves the list unchanged and shows a one-time notice

- **WHEN** the store rejects the write of an add, rename, delete, or payment method correction, or reading the orders affected by a payment method correction fails
- **THEN** the list and every consumer's selectable values are unchanged, a dismissible notice states which operation failed, and no message is added above the list

##### Example: failure notices per operation

| Operation | List after failure | Notice message |
| --------- | ------------------ | -------------- |
| add "手工藝品" to categories ["服飾"] | ["服飾"] | 新增失敗，請稍後再試。 |
| rename "服飾" to "衣著" in ["服飾"] | ["服飾"], orders still reference "服飾" | 重新命名失敗，請稍後再試。 |
| delete "服飾" from ["服飾"] | ["服飾"] | 刪除失敗，請稍後再試。 |
| correct "信用卡" to cash on delivery, the atomic write fails | 信用卡 keeps its previous flags, orders unchanged | 付款方式編輯失敗，請稍後再試。 |
| correct "信用卡", reading the affected orders fails | 信用卡 keeps its previous flags, orders unchanged | 付款方式編輯失敗，請稍後再試。 |

#### Scenario: A rename writes the stored lookup and the stored orders in one transaction

- **WHEN** the user renames a lookup item
- **THEN** the stored lookup and every stored order that references the old name are updated in a single save, so either both reflect the new name or, if the save fails, both keep their previous state; on failure the list and every consumer still show the previous values, a one-time notice states that the rename failed, and no rename delegate action is emitted

##### Example: renames with a failing save

| Stored categories before | Stored orders before | Rename | Stored categories after | Stored orders after |
| ------------------------ | -------------------- | ------ | ----------------------- | ------------------- |
| ["服飾"] | A: 服飾 | 服飾 → 衣著 | ["服飾"] | A: 服飾 |
| ["服飾", "衣著"] | A: 服飾, B: 衣著 | 服飾 → 衣著 | ["服飾", "衣著"] | A: 服飾, B: 衣著 |

##### Example: a rename onto an existing name that succeeds

- **GIVEN** the stored categories are ["服飾", "衣著"] and order A references "服飾"
- **WHEN** the user renames "服飾" to "衣著" and the save succeeds
- **THEN** the stored categories are ["衣著"] and order A references "衣著"

#### Scenario: A notice that is ready while the form is closing appears after the form closes

- **WHEN** an add, rename, or payment method edit is submitted from its form, and the write failure notice or the retroactive confirmation is ready before the form has finished closing
- **THEN** the notice or confirmation is held until the form has closed and is then shown once; one that becomes ready after the form has closed is shown immediately

##### Example: an add that the store rejects immediately

- **GIVEN** the categories are ["服飾"] and the store rejects every write without delay
- **WHEN** the user submits "失敗類別" from the add form
- **THEN** the form closes first, the notice 新增失敗，請稍後再試。 then appears, and the list stays ["服飾"]

#### Scenario: Dismissing a failure notice clears it

- **WHEN** the user dismisses a write-failure notice
- **THEN** the notice is gone, and it does not reappear on later successful operations

#### Scenario: The initial load failure stays above the list

- **WHEN** the screen's initial load of a lookup kind fails
- **THEN** the load-failure message is shown above the list until a later load succeeds

#### Scenario: iOS swipe-to-delete is retained

- **WHEN** the user swipes an item row on iOS or iPadOS
- **THEN** the swipe actions for delete and rename are available, unchanged from before this change

#### Scenario: An unresolvable management screen is visibly failed, not blank

- **WHEN** the management screen for a requested lookup kind cannot be resolved
- **THEN** the load-failure view is shown instead of an empty screen

### Requirement: Lookup data has a single source shared by every consumer

The four lookup kinds — order source, category, payment method, and reconciliation status — SHALL be held in one store shared by every consumer, rather than copied into each feature that reads them. A consumer SHALL derive its view of a lookup kind from that store rather than maintaining its own collection.

Adding, renaming, or deleting a lookup item SHALL update the shared lookup store, and therefore every list derived from it (the management list and the order editor's selectable values), within the same state update once its write succeeds, without requiring a separate action or a root-level interception to propagate it to those lists. The in-memory orders are not derived from the shared lookup store; when a rename must rewrite them, that rewrite is the root feature's response to the management feature's delegate action, as described below.

Consistency SHALL NOT depend on hand-written synchronization between copies. Where a lookup change must also rewrite orders held in memory, the management feature SHALL report the completed change to the root feature through a delegate action carrying the old and new names, and the root feature SHALL rewrite the in-memory orders in response to that delegate action, so that a derived list that unions lookup values with values used by orders never contains the old name once the rename has completed.

#### Scenario: Renaming reaches every consumer once the write succeeds

- **WHEN** a lookup item of any kind is renamed and the write succeeds
- **THEN** the management list and the order editor's selectable values for that kind are updated in the same state update, and the orders referencing the old value are rewritten by the root feature when it receives the management feature's rename delegate action

##### Example: renaming a category

- **GIVEN** the categories are ["美妝", "服飾"] and an in-memory order has categories ["美妝"]
- **WHEN** the user renames "美妝" to "彩妝保養" and the write succeeds
- **THEN** the categories become ["服飾", "彩妝保養"], the management feature emits a delegate action carrying "美妝" and "彩妝保養", and after the root feature handles it the order has categories ["彩妝保養"]

#### Scenario: A rename never leaves the old name reachable

- **WHEN** a lookup item is renamed and a selectable list unions lookup values with values already used by orders
- **THEN** that list does not contain the old name once the root feature has handled the rename delegate action

#### Scenario: A failed rename rewrites no orders

- **WHEN** a rename is rejected by the store
- **THEN** no rename delegate action is emitted and the in-memory orders still reference the old name

#### Scenario: Adding inside the order editor is visible in management

- **WHEN** the user adds a lookup item from within the order editor
- **THEN** the item appears on that kind's management screen without relaunching the app

#### Scenario: Deleting removes the value from every consumer

- **WHEN** a lookup item is deleted and the write succeeds
- **THEN** the order editor no longer offers it as a selectable value

### Requirement: Adding a lookup kind is a compile-time obligation

The differences between lookup kinds — how an order references a value of that kind, and how an order is rewritten when that value is renamed — SHALL be expressed on the lookup-kind type itself as exhaustive mappings, so that introducing a new kind fails to compile until those differences are supplied.

Consumers SHALL NOT branch on lookup kind to perform these operations; they SHALL delegate to the kind. Introducing a new kind SHALL NOT require adding a parallel property, action case, or scope in the root feature.

Which storage each lookup kind reads and writes SHALL be dispatched in one place inside the lookups feature, as an exhaustive mapping over the kinds, so that the management feature itself does not repeat a branch over the kinds for each operation.

#### Scenario: A new kind does not compile until its differences are supplied

- **WHEN** a new lookup kind is added to the lookup-kind type
- **THEN** compilation fails until that kind supplies how orders reference it, how orders are rewritten on rename, and which storage it reads and writes

#### Scenario: Compilation errors are confined to the lookups feature

- **WHEN** a new lookup kind is added and the project is built
- **THEN** the errors appear only in files of the lookups feature (the lookup-kind type, the shared lookup store, the single storage dispatch, and the management view's per-kind rename title), not in the root feature or the orders feature

#### Scenario: Cascade contains no per-kind branching at the call site

- **WHEN** the cascade that rewrites orders after a rename is inspected
- **THEN** it delegates to the lookup kind and contains no branch over the set of kinds

## ADDED Requirements

### Requirement: Payment method classification lookup tolerates duplicate names

The payment method classification shown on the management screen and used to pre-fill the payment method editor SHALL be read through a single lookup by name on the shared lookup store. The lookup SHALL NOT assume that payment method names are unique, because the store has no uniqueness constraint; when several entries share a name, it SHALL use the first entry in the stored order. A name with no entry SHALL read as having no classification flags set.

#### Scenario: Duplicate payment method names do not terminate the screen

- **WHEN** the stored payment methods contain two entries with the same name
- **THEN** the management screen lists the payment methods and shows the classification badges of the first entry for that name, without terminating

##### Example: classification lookup by name

| Stored entries (in order) | Looked-up name | Flags read |
| ------------------------- | -------------- | ---------- |
| 匯款 (bank transfer), 匯款 (cardless) | 匯款 | bank transfer only |
| 信用卡 (none) | 信用卡 | none |
| 信用卡 (none) | 貨到付款 | none |
