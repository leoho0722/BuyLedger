## REMOVED Requirements

### Requirement: Filter orders by campaign status

**Reason**: No screen ever offered this filter. The state and actions existed only in the orders feature and its tests, the filter computed a campaign status lookup on every filtering pass without any view sending the action, and keeping it would force the new order list feature to carry dead state. The campaigns tab's own "篩選與分組" is a separate feature and is unaffected.
**Migration**: None for users, since no screen exposed the filter. Code that set the selected campaign status is removed together with its tests.

### Requirement: Filter orders by a specific campaign

**Reason**: Same as the campaign status filter: no view ever sent the action, so the requirement described behavior that users could not reach.
**Migration**: None for users. Narrowing orders by campaign remains available through the campaign detail screen, which lists the orders of one campaign.
