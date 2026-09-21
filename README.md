# 🚀 Infrastructure Cloud Deployments (`infra-cloud-deployments`)

This repository serves as the dedicated, automated GitOps deployment engine for hybrid multi-cloud infrastructure (Microsoft Azure, AWS, and Cloudflare), decoupled from local workstations and the architecture documentation vault.

---

## 🔒 Security Architecture: Zero-Trust OIDC Federation

This repository operates strictly on **OpenID Connect (OIDC) Workload Identity Federation**:

1. **Zero Static Credentials**: No `ARM_CLIENT_SECRET`, AWS Access Keys, or permanent passwords are saved in GitHub Secrets.
2. **Ephemeral Identity Minting**:
   * Each workflow job requests a cryptographic JSON Web Token (JWT) directly from `token.actions.githubusercontent.com`.
   * Microsoft Entra ID validates the signature and subject claim (`repo:bar2sek/infra-cloud-deployments:environment:production`).
   * Entra ID mints a short-lived OAuth access token scoped strictly to the authorized permissions of `sp-azure-github-actions-prod-001`.
3. **Auditability & Traceability**:
   * Every Azure resource modification links directly to the specific GitHub Actions execution, pull request ID, and Git commit hash in Azure Activity Logs.

---

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── azure-deploy.yml     # Automated CI/CD pipeline (Lint, Plan, Apply)
├── terraform/
│   └── azure/                  # Azure cloud infrastructure & workloads
│       ├── providers.tf        # Azure provider & AzureRM remote state backend
│       ├── main.tf             # Cloud resources & network landing zones
│       ├── variables.tf        # Input variable definitions
│       └── outputs.tf          # Resource outputs
└── README.md
```

---

## 🚦 Deployment Lifecycle & Protection Gates

* **Pull Request (`pull_request`)**:
  * Runs `terraform fmt -check`, `terraform init`, and `terraform validate`.
  * Runs `terraform plan` against Azure and outputs the planned changes into the PR review summary.
  * State remains unmutated (read-only execution).
* **Merge to Main (`push`)**:
  * Triggers the `production` GitHub Environment.
  * Respects environment protection rules (manual approval gates, required branch policies).
  * Executes `terraform apply -auto-approve` to deploy changes to Azure.
  * Automatically records deployment history in GitHub Deployments dashboard.

---

## ⚙️ Declarative Governance

This repository, its environments (`production`), protection policies, and environment variables (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) are managed declaratively via Terraform from `personal-technology/terraform/github/`.
