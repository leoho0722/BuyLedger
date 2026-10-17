## MODIFIED Requirements

### Requirement: Payment method editing via the editor sheet

For the payment method kind, the per-item edit action SHALL be labeled "編輯" and SHALL present the payment method editor pre-filled with the item's current name, cardless flag, and bank-transfer flag. Confirming SHALL apply the edited name and flags authoritatively: changing the name SHALL rename the item and cascade to orders referencing the old name, and the cardless and bank-transfer flags SHALL be set to exactly the user's selection — including clearing a previously-set flag. The edit action SHALL be available from every per-item entry point that previously offered rename (iOS swipe, iOS context menu). Other lookup kinds (order source, category, reconciliation status) SHALL retain the rename-only action labeled "重新命名".

Applying flags authoritatively SHALL extend to orders already using the payment method. The flags govern how an order's finances are computed, so leaving existing orders on the previous flags would keep computing them from a state the user has just corrected. Existing orders SHALL therefore be recomputed using the same normalization the order editor applies, and SHALL be written together with the lookup update so that a failure applies neither.

The orders recomputed SHALL be the stored orders that use the payment method when the write runs, read inside the same transaction as the lookup update, so that the recomputation never overwrites an order with values read earlier and does not depend on whether the orders have been loaded into memory. Once the write succeeds, every in-memory order among them SHALL be replaced with the order that write produced.

Because recomputation rewrites stored values of existing orders and cannot be undone, it SHALL be confirmed before it runs. The confirmation SHALL state how many stored orders use the payment method when the edit is requested. Declining SHALL leave both the orders and the lookup flags unchanged, so that the lookup and the orders never disagree. An edit that leaves the flags unchanged, or that no stored order uses, SHALL be written without confirmation.

#### Scenario: Edit a payment method's name and flags

- **WHEN** the user activates "編輯" on a payment method, changes its name, and confirms
- **THEN** the payment method is renamed, orders referencing the old name are updated, and its cardless and bank-transfer flags reflect the user's selection

#### Scenario: Correcting a missed cash-on-delivery flag fixes existing profit

- **WHEN** the user sets the cash-on-delivery flag on a payment method that orders already use, and confirms the recomputation
- **THEN** those orders are recomputed so that the three shipping amounts are included in their cost, and their reported profit changes accordingly

#### Scenario: Confirmation states the blast radius

- **WHEN** a flag change would affect existing orders
- **THEN** the confirmation states the number of orders that will be recomputed

#### Scenario: Declining leaves everything unchanged

- **WHEN** the user declines the recomputation confirmation
- **THEN** neither the orders nor the payment method's flags are changed

#### Scenario: Recomputation and lookup update are atomic

- **WHEN** persistence fails while recomputing affected orders
- **THEN** neither the orders nor the payment method's flags are changed

#### Scenario: Clearing the cardless flag clears dependent amounts

- **WHEN** the user clears the cardless flag on a payment method that orders already use, and confirms
- **THEN** those orders' cardless deduction and supplement amounts become zero, matching what the order editor would produce

#### Scenario: Recomputation reads the orders stored when the write runs

- **WHEN** the user confirms a flag change on a payment method
- **THEN** the orders recomputed are the stored orders using that payment method at the time of the write, including any that are not held in memory

##### Example: orders not yet loaded into memory

- **GIVEN** stored orders A and B use "信用卡", 信用卡 has no flags set, and the in-memory orders are empty because loading has not finished
- **WHEN** the user sets the cash-on-delivery flag on 信用卡, the confirmation states 2 orders, and the user confirms
- **THEN** stored orders A and B are both recomputed with cash-on-delivery applied, and 信用卡 has the cash-on-delivery flag

### Requirement: Lookup data has a single source shared by every consumer

The four lookup kinds — order source, category, payment method, and reconciliation status — SHALL be held in one store shared by every consumer, rather than copied into each feature that reads them. A consumer SHALL derive its view of a lookup kind from that store rather than maintaining its own collection.

Only the lookup side SHALL write the shared lookup store: the management screens and a lookup catalog feature that has no view of its own. The catalog feature SHALL store an option that the order editor adds, and SHALL read the four kinds from storage before the orders are loaded: every request to load the orders, at launch or from a retry, SHALL first ask the catalog feature, which reads the four kinds unless it has already read all of them successfully, and the orders SHALL be loaded once it has finished. A kind whose read fails SHALL keep its previous values, and the orders SHALL still be loaded afterwards. Order features SHALL hold the shared lookup store read-only and SHALL NOT read or write lookup storage themselves.

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

#### Scenario: The lookup catalog is read before the orders load

- **WHEN** the orders are requested to load, at launch or from a retry
- **THEN** the lookup catalog feature finishes reading the four lookup kinds from storage, or confirms it already has all of them, before the orders are loaded, and the order loading reads only the orders

##### Example: categories available in the first editor opened

- **GIVEN** the stored categories are ["服飾", "美妝"]
- **WHEN** the app launches and the user opens a new order editor as soon as the orders have loaded, without visiting the categories management screen
- **THEN** the editor's category list contains 服飾 and 美妝

##### Example: one kind fails to read

| Before the read | Read results | After the read |
| --------------- | ------------ | -------------- |
| categories [], payment methods [] | categories ["服飾"] succeeds, payment methods fails | categories ["服飾"], payment methods [], the orders are loaded, and the next orders load request reads the four kinds again |
| categories ["服飾"], payment methods ["信用卡"] after all four kinds were read successfully | no read runs | unchanged, and the orders are loaded |

#### Scenario: Order features cannot write the lookup store

- **WHEN** the order features are inspected
- **THEN** they declare the shared lookup store read-only and do not obtain the lookup service

#### Scenario: Deleting removes the value from every consumer

- **WHEN** a lookup item is deleted and the write succeeds
- **THEN** the order editor no longer offers it as a selectable value
