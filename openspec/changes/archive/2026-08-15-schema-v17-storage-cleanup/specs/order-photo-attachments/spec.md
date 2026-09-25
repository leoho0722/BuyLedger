## ADDED Requirements

### Requirement: Order photo bytes live outside the order row

Order photos SHALL be persisted as binary payloads stored adjacent to the order record rather than inline in it, so that reading an order without reading its photos does not load the payloads. Where the persistence framework does not honour this for the stored shape, the read paths SHALL still exclude the photo attribute explicitly, and the observable contract of the remaining requirements SHALL hold regardless.

#### Scenario: Reading an order without its photos loads no payloads

- **WHEN** order records are read through a path that does not request the photo attribute
- **THEN** the photo payloads are not loaded into memory

#### Scenario: Payload relocation is transparent to callers

- **WHEN** an order with photos is saved and read back through the photo-loading path
- **THEN** the returned photos are byte-for-byte identical to what was saved

### Requirement: Order collection reads exclude photo bytes

The read path that returns all orders SHALL return each order with an empty photo list and SHALL declare the attributes it fetches so that the photo attribute is excluded. Photo bytes SHALL be obtainable only through a separate read addressed by order identifier. Consequently an empty photo list on an order obtained from a collection read SHALL NOT be interpreted as the order having no photos.

#### Scenario: Collection read carries no photo bytes

- **WHEN** all orders are read and one of them has stored photos
- **THEN** that order is returned with an empty photo list

#### Scenario: Photos are retrievable by order identifier

- **WHEN** the photos of a stored order are requested by its identifier
- **THEN** the stored photos are returned in their persisted order

#### Scenario: Requesting photos for an unknown order is not an error

- **WHEN** photos are requested for an identifier that matches no stored order
- **THEN** an empty list is returned rather than an error being raised

### Requirement: Writes that do not carry photos leave stored photos intact

Applying a domain order onto an existing order record SHALL NOT write the photo attribute. Photos SHALL be written only through a distinct write that requires the caller to supply the photo list explicitly. Creating a new order record SHALL persist the photos supplied with it. As a result, any write path that does not explicitly carry photos SHALL leave the stored photos unchanged rather than clearing them.

#### Scenario: Batch status change preserves photos

- **WHEN** several orders including one with photos have their status changed in a batch write that carries no photos
- **THEN** the stored photos of that order are unchanged

#### Scenario: Master-data rename preserves photos

- **WHEN** an order source, category, payment method, reconciliation status, or campaign referenced by an order with photos is renamed and the order is rebuilt and written back without photos
- **THEN** the stored photos of that order are unchanged

#### Scenario: A newly created order keeps the photos it was created with

- **WHEN** an order that does not yet exist is written with a non-empty photo list
- **THEN** the photos are persisted with the new record

#### Scenario: Explicit photo write replaces the stored set

- **WHEN** an existing order is written through the photo-carrying write with a different photo list
- **THEN** the stored photos are replaced by the supplied list

## MODIFIED Requirements

### Requirement: Photos persist with the order

Order photos SHALL share the order's lifecycle: deleting the order removes its photos, and reopening the edit form for a persisted order SHALL show its stored photos. Saving an order SHALL persist the current draft photos only when the draft has been loaded and the user has changed it; otherwise the save SHALL leave the stored photos untouched. Rebuilding an order during master-data cascade renames SHALL leave the stored photos unchanged.

The edit form SHALL load a persisted order's photos on demand rather than receiving them with the order. Until that load succeeds, the form SHALL show the load state and SHALL disable the controls that add or remove photos, so that a failed or pending load cannot be mistaken for the user emptying the set.

#### Scenario: Photos survive app relaunch

- **WHEN** the user saves an order with 2 photos, terminates the app, relaunches, and reopens the edit form for that order
- **THEN** the form shows the same 2 photos

#### Scenario: Master-data rename keeps photos

- **WHEN** an order source, category, payment method, reconciliation status, or campaign referenced by an order with photos is renamed
- **THEN** the order still has the identical photo data

#### Scenario: Saving before the photo load completes keeps stored photos

- **WHEN** the user opens an order with photos and saves it before the photo load completes
- **THEN** the stored photos are unchanged, and no empty photo list is written

#### Scenario: A failed photo load is visible and non-destructive

- **WHEN** loading a persisted order's photos fails
- **THEN** the edit form shows the failure, the add and remove controls are disabled, and saving the order leaves the stored photos unchanged

#### Scenario: Editing photos writes the edited set

- **WHEN** the photo load completes and the user adds or removes a photo before saving
- **THEN** the stored photos match the edited draft
