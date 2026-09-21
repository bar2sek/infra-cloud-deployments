# 🚀 Infrastructure Cloud Deployments (`infra-cloud-deployments`)

This repository serves as the dedicated, automated GitOps deployment engine for hybrid multi-cloud infrastructure (Microsoft Azure, AWS, and Cloudflare), decoupled from local workstations and the architecture documentation vault.

---

## 🔒 Security Architecture: Zero-Trust OIDC Federation

This repository operates strictly on **OpenID Connect (OIDC) Workload Identity Federation**:

1. **Zero Static Credentials**: No `ARM_CLIENT_SECRET`, AWS Access Keys, or permanent passwords are saved in GitHub Secrets.
2. **Ephemeral Identity Minting (Azure)**:
   * Each workflow job requests a cryptographic JSON Web Token (JWT) directly from `token.actions.githubusercontent.com`.
   * Microsoft Entra ID validates the signature and subject claim (`repo:bar2sek/infra-cloud-deployments:environment:production`).
   * Entra ID mints a short-lived OAuth access token scoped strictly to the authorized permissions of `sp-azure-github-actions-prod-001`.
3. **Ephemeral Identity Minting (AWS)**:
   * The same GitHub-issued JWT is exchanged with AWS STS via `aws-actions/configure-aws-credentials`.
   * AWS validates the token against the GitHub OIDC identity provider and assumes the role referenced by the `AWS_ROLE_TO_ASSUME` environment variable, returning temporary STS credentials.
4. **Auditability & Traceability**:
   * Every Azure resource modification links directly to the specific GitHub Actions execution, pull request ID, and Git commit hash in Azure Activity Logs.
   * AWS resources carry `default_tags` (`Environment`, `ManagedBy = github-actions`, `Repository`) so every object traces back to this pipeline, with API-level attribution in CloudTrail.

---

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── azure-deploy.yml        # Azure CI/CD pipeline (Lint, Plan, Apply)
│       └── aws-deploy.yml          # AWS CI/CD pipeline (Lint, Plan, Apply)
├── terraform/
│   ├── azure/                      # Azure cloud infrastructure & workloads
│   │   ├── providers.tf            # Azure provider & AzureRM remote state backend
│   │   ├── main.tf                 # Cloud resources & network landing zones
│   │   ├── variables.tf            # Input variable definitions
│   │   └── outputs.tf              # Resource outputs
│   └── aws/                        # AWS cloud infrastructure & workloads
│       ├── providers.tf            # AWS provider, S3 backend & DynamoDB state locking
│       ├── locals.tf               # Canonical resource naming convention
│       ├── main.tf                 # S3 backup bucket & EKS connector IAM role
│       ├── variables.tf            # Input variable definitions
│       ├── outputs.tf              # Resource outputs
│       └── .terraform.lock.hcl     # Pinned provider checksums (tracked)
└── README.md
```

> [!NOTE] Resource Naming Convention
> AWS resources are composed in `terraform/aws/locals.tf` following `<abbrev>-aws-<product>-<env>-<region-code>-<iteration>` (e.g. `s3-aws-backups-prod-use2-001`). IAM roles follow `role-aws-<purpose>-<env>-admin`. Extend the `locals` block rather than hardcoding names inline.

> [!WARNING] Local Provider Cache
> Running `terraform init` locally materializes `.terraform/` directories containing provider binaries that can exceed **600 MB per provider**. These are gitignored, but if this repository is cloned inside a cloud-synced folder, clear them after local plan sessions:
> ```bash
> rm -rf terraform/*/.terraform
> ```

---

## 🚦 Deployment Lifecycle & Protection Gates

Both `azure-deploy.yml` and `aws-deploy.yml` follow an identical two-stage gate:

* **Pull Request (`pull_request`)**:
  * Runs `terraform fmt -check`, `terraform init`, and `terraform validate`.
  * Runs a speculative `terraform plan` and outputs the planned changes into the PR review summary.
  * State remains unmutated (read-only execution).
* **Merge to Main (`push`)**:
  * Triggers the `production` GitHub Environment.
  * Respects environment protection rules (manual approval gates, required branch policies).
  * Executes `terraform apply -auto-approve` to deploy changes.
  * Automatically records deployment history in GitHub Deployments dashboard.

> [!IMPORTANT]
> Never bypass the PR plan gate by pushing directly to `main`. The speculative plan is the only review surface between a code change and a mutated cloud resource.

---

## 🗄️ Remote State Backends

State is **never** stored locally or committed to Git.

| Plane | Backend | Locking |
| :--- | :--- | :--- |
| AWS (`terraform/aws/`) | S3 bucket, server-side encrypted, key `aws-workloads/terraform.tfstate` (`us-east-2`) | DynamoDB table |
| Azure (`terraform/azure/`) | AzureRM Blob Storage container | Native blob lease |

---

## ⚙️ Declarative Governance

This repository, its `production` environment, branch protection policies, and its Actions configuration are managed declaratively via Terraform from the `bootstrap/github/` module in the `personal-technology` repository.

Values are published at **two scopes**, because GitHub resolves lookups with precedence `environment > repository > organization`:

* **Repository scope** — the shared baseline. This is what the PR `plan` job reads; that job deliberately declares no `environment:`, since adding one would subject every pull request to the production approval gate.
* **Environment scope** — `production` overrides, and the extension point for future `staging`/`dev` environments.

| Name | Kind | Why |
| :--- | :--- | :--- |
| `AZURE_CLIENT_ID` | Variable | Identifier, not a credential — useless without a matching federated credential |
| `AZURE_TENANT_ID` | Variable | As above |
| `AZURE_SUBSCRIPTION_ID` | Variable | As above |
| `AWS_ROLE_TO_ASSUME` | Variable | An ARN grants nothing without a matching IAM trust policy |
| `AWS_REGION` | Variable | Non-sensitive |
| `AWS_TF_STATE_BUCKET` | **Secret** | Embeds the AWS account ID and is interpolated into a `run:` command, which Actions echoes verbatim into logs. A secret is masked to `***`; a variable is not. |

> [!NOTE]
> Under OIDC there is no static credential to protect, which is why the identifiers above are variables rather than secrets. Keeping them readable also lets Terraform detect drift — `github_actions_secret` is write-only, so Terraform tracks a hash and cannot see out-of-band edits made in the GitHub UI.

---

## 🧭 Repository Boundary

This repository is the cloud **execution plane**. Keep the split clean:

| Belongs here | Belongs in `personal-technology` |
| :--- | :--- |
| AWS / Azure / Cloudflare resources deployed by CI/CD | On-prem Talos, Kubernetes, Ceph, KubeVirt manifests |
| Pipeline-owned remote state and OIDC trust policies | UniFi network provisioning, Ansible playbooks |
| Cloud landing zones and IAM | `nix-mac` workstation state, GitHub governance modules |

Never define the same resource in both repositories—ownership follows whichever plane controls its lifecycle.
