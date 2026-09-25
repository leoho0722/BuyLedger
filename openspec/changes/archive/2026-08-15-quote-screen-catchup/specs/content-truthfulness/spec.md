## MODIFIED Requirements

### Requirement: Failed loads offer a retry path within the screen

A screen whose content fails to load SHALL offer a retry control within the screen itself. Recovery SHALL NOT depend on the user leaving and re-entering the screen, because that requirement is not communicated anywhere in the interface.

This applies equally to a screen whose computation depends on data it did not load itself. Presenting a placeholder in place of a number satisfies the rule against fabricated data, but on its own it leaves the user unable to tell whether the value is missing, still loading, or permanently unavailable. Such a screen SHALL also state why the value is unavailable and offer the same in-screen retry.

#### Scenario: Exchange rate failure offers retry

- **WHEN** exchange rate loading fails and the exchange rate screen is presented
- **THEN** a retry control is available alongside the failure message, and activating it attempts the load again

#### Scenario: Retry restores content on success

- **WHEN** the user activates retry and the load succeeds
- **THEN** the failure message is replaced by the loaded content

#### Scenario: A dependent screen explains and offers retry

- **WHEN** the quote screen cannot compute because no usable exchange rate is available
- **THEN** it states why the rate is unavailable and offers a retry control, rather than showing placeholders alone
