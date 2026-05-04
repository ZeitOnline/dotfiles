#!/bin/bash
#
# Create short, per-namespace kubectl contexts of the form
#   <namespace>-<environment>
# (e.g. ``account-server-staging``) so that one can run
#
#   kubectl --context account-server-staging get pods
#
# instead of having to remember the long, generation-suffixed
# ``gke_<project>_<region>_<cluster>`` names that ``gcloud`` emits and that
# change whenever a new cluster generation is rolled out.
#
# This script is a chezmoi ``run_after_*`` script, so it runs *after*
# ``run_gcloud_credentials.sh`` on every ``chezmoi apply`` and re-stamps the
# alias contexts against whatever the current cluster names are.
#
# To add or remove environments, edit the ``ENV_*`` arrays below. The list of
# namespaces per environment is discovered dynamically by querying each
# cluster for namespaces that carry the ``zon.zeit.de/owner`` annotation.

set -euo pipefail

# Make sure we operate on the global kubeconfig and not on some project-local
# ``./kube.config`` that may be present via ``$KUBECONFIG`` (see
# ``private_dot_config/private_fish/conf.d/zon.fish``).
unset KUBECONFIG

# Path to the *main* kubeconfig (read-only here — we only use it to verify
# that the gcloud-generated cluster contexts exist).
MAIN_KUBECONFIG="${HOME}/.kube/config"

# Path to the *separate*, opt-in kubeconfig that this script (re)generates.
# Colleagues who don't want the dozens of per-namespace alias contexts in
# their main config can simply ignore this file. Those who want them can
# opt in by exporting e.g.
#
#   export KUBECONFIG="$HOME/.kube/config:$HOME/.kube/namespace-contexts"
#
# in their shell rc.
ALIAS_KUBECONFIG="${HOME}/.kube/namespace-contexts"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Mapping: environment -> ``gcloud``-generated context/cluster/user name.
# Whenever a cluster generation changes (e.g. ``main-staging-25-01`` ->
# ``main-staging-26-01``), update the right-hand side here and re-run
# ``chezmoi apply``.
#
# Stored as parallel arrays (instead of an associative array) so that this
# script also works with bash 3.2, which is the default ``/bin/bash`` on
# macOS and does not support ``declare -A``.
ENV_NAMES=(
  devel
  staging
  production
)
ENV_CLUSTERS=(
  "gke_zeitonline-main_europe-west3-a_devel"
  "gke_zeitonline-main_europe-west3_main-staging-25-01"
  "gke_zeitonline-main_europe-west3_main-production-25-01"
)

# Annotation key used to identify namespaces that belong to a team and should
# get an alias context. Namespaces without this annotation (kube-system,
# default, gatekeeper-system, ...) are skipped.
OWNER_ANNOTATION="zon.zeit.de/owner"


# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH; skipping namespace context generation." >&2
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found in PATH; skipping namespace context generation." >&2
  exit 0
fi

# Existing contexts in the *main* kubeconfig (used to verify the cluster
# contexts gcloud should have created actually exist before we try to alias
# them).
existing_contexts="$(KUBECONFIG="$MAIN_KUBECONFIG" kubectl config get-contexts -o name 2>/dev/null || true)"

# ---------------------------------------------------------------------------
# Reset the alias kubeconfig
# ---------------------------------------------------------------------------
#
# We rewrite the file from scratch on every run so that removed namespaces or
# environments don't leave stale entries behind.
mkdir -p "$(dirname "$ALIAS_KUBECONFIG")"
rm -f "$ALIAS_KUBECONFIG"

# All subsequent ``kubectl config`` calls write to the alias file only.
export KUBECONFIG="$ALIAS_KUBECONFIG"

# ---------------------------------------------------------------------------
# Generate alias contexts
# ---------------------------------------------------------------------------

for i in "${!ENV_NAMES[@]}"; do
  env="${ENV_NAMES[$i]}"
  cluster="${ENV_CLUSTERS[$i]}"

  if ! grep -Fxq "$cluster" <<<"$existing_contexts"; then
    echo "warning: base context '$cluster' for env '$env' not found; " \
         "did 'gcloud container clusters get-credentials' run successfully?" >&2
    continue
  fi

  # Discover namespaces in this cluster that carry the owner annotation.
  # We query the *main* kubeconfig (the alias file we're writing into has no
  # cluster/user definitions of its own).
  if ! namespaces_json="$(KUBECONFIG="$MAIN_KUBECONFIG" kubectl --context "$cluster" get namespaces -o json 2>/dev/null)"; then
    echo "warning: failed to list namespaces for env '$env' (context '$cluster'); skipping." >&2
    continue
  fi

  namespaces=$(jq -r --arg ann "$OWNER_ANNOTATION" \
    '.items[] | select(.metadata.annotations[$ann] != null) | .metadata.name' \
    <<<"$namespaces_json")

  if [[ -z "$namespaces" ]]; then
    echo "warning: no annotated namespaces found in env '$env'." >&2
    continue
  fi

  while IFS= read -r ns; do
    [[ -z "$ns" ]] && continue
    alias_name="${ns}-${env}"
    kubectl config set-context "$alias_name" \
      --cluster="$cluster" \
      --user="$cluster" \
      --namespace="$ns" \
      >/dev/null
  done <<<"$namespaces"
done
