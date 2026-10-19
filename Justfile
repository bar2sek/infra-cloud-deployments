# ==============================================================================
# Infra Cloud Deployments - Local Terraform runner (just)
# ==============================================================================
# CI owns `apply` (push to main -> protected `production` environment), so there
# is deliberately no apply recipe here: locally you init, validate and plan.
#
# Every recipe runs Terraform through `_tf`, which keeps `.terraform/` out of the
# Google Drive–synced vault:
#   * TF_DATA_DIR  -> ~/.terraform-data/infra-cloud-deployments/<provider>
#                     (one per root: it also holds the backend metadata)
#   * TF_PLUGIN_CACHE_DIR -> ~/.terraform.d/plugin-cache, shared with other repos
#   * auto-runs `terraform init` (with backend.hcl when present) when the root
#     has not been initialised against its backend yet

tf_data_root := env_var_or_default("TF_DATA_ROOT", env_var("HOME") / ".terraform-data") / "infra-cloud-deployments"

# Default recipe: List available commands
default:
    @just --list

[private]
[positional-arguments]
_tf dir cmd *args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="$1" cmd="$2"; shift 2
    root="terraform/$dir"
    [ -d "$root" ] || { echo "Error: Directory $root not found" >&2; exit 1; }
    export TF_DATA_DIR="{{ tf_data_root }}/$dir"
    export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
    # Same default as the nix-mac `terraform` alias (shell aliases don't apply inside just).
    export AWS_PROFILE="${AWS_PROFILE:-terraform}"
    mkdir -p "$TF_DATA_DIR" "$TF_PLUGIN_CACHE_DIR"
    cd "$root"
    # Partial backend: the state bucket name comes from the gitignored backend.hcl.
    backend_args=()
    if [ -f backend.hcl ] && [[ " $* " != *" -backend=false "* ]]; then
        backend_args=(-backend-config=backend.hcl)
    fi
    if [ "$cmd" = "init" ]; then
        exec terraform init ${backend_args[@]+"${backend_args[@]}"} "$@"
    fi
    # terraform.tfstate in the data dir is the backend pointer; without it a plan
    # fails with "Backend initialization required".
    if [ ! -d "$TF_DATA_DIR/providers" ] || [ ! -f "$TF_DATA_DIR/terraform.tfstate" ]; then
        echo "===> $root: not initialised in $TF_DATA_DIR, running terraform init"
        terraform init -input=false ${backend_args[@]+"${backend_args[@]}"}
    fi
    terraform "$cmd" "$@"

# Initialise a root outside the vault (usage: just tf-init aws, just tf-init aws -upgrade)
[positional-arguments]
tf-init dir *args:
    @d="$1"; shift; {{ just_executable() }} _tf "$d" init "$@"

# Speculative plan without taking the state lock, so it never blocks a CI apply (usage: just tf-plan aws)
[positional-arguments]
tf-plan dir *args:
    @d="$1"; shift; {{ just_executable() }} _tf "$d" plan -lock=false "$@"

# Run any other Terraform subcommand in a root (usage: just tf aws validate)
[positional-arguments]
tf dir cmd *args:
    @{{ just_executable() }} _tf "$@"

# Check formatting across all roots, as the PR gate does
tf-fmt-check:
    terraform fmt -check -recursive terraform
