# Example Corp — Information Security Policy

> Synthetic document for a retrieval-augmented generation (RAG) lab. Example Corp is fictional.

**Policy owner:** Security Engineering · **Effective:** 2026-02-15 · **Version:** 4.1

## Authentication
- Multi-factor authentication (MFA) is mandatory for every company account. Phishing-resistant methods — **passkeys or hardware security keys** — are required for administrators and anyone with production access.
- SMS codes are not an accepted second factor.
- Passwords must be at least **16 characters** and stored only in the company password manager.

## Data classification
| Level | Examples | Rules |
| :--- | :--- | :--- |
| **Public** | Marketing pages, published docs | No restrictions |
| **Internal** | Org charts, internal wikis | Employees only |
| **Confidential** | Customer contracts, financial forecasts | Need-to-know; encrypted at rest and in transit |
| **Restricted** | Customer personal data, credentials, encryption keys | Named-access only; never pasted into chat tools or AI assistants that are not company-approved |

## Generative AI use
- Only company-approved AI tools may be used with Internal or Confidential data.
- Restricted data must never be entered into any AI tool.

## Incident reporting
- Report a suspected security incident to the security team within **1 hour** of discovery via the #security-incidents channel or the on-call pager.
- Lost or stolen devices must be reported within **1 hour**, so they can be remotely wiped.
