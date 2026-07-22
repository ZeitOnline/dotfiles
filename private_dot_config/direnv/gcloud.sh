# use gcloud_registry [--export-token]
#
# Make Google Artifact Registry auth work *lazily*, with no per-`cd` penalty:
#   * uv     -> keyring backend (keyrings.google-artifactregistry-auth). We only
#               set UV_KEYRING_PROVIDER and sanity-check; uv mints+caches a token
#               itself, and only when it actually contacts the private index.
#   * docker -> gcloud credential helper, configured once per machine via
#               `gcloud auth configure-docker europe-west3-docker.pkg.dev`.
#
# With --export-token it additionally exports GOOGLE_AR_ACCESS_TOKEN from a
# single machine-wide cache for tools that can't use keyring/credHelper. The
# cache is shared by all projects and refreshed in the background, so entering a
# directory never blocks on `gcloud`.
use_gcloud_registry() {
    export UV_KEYRING_PROVIDER=subprocess

    # Cheap, no-network sanity hints. These warn but never block the shell.
    if ! has keyring; then
        log_status "gcloud_registry: 'keyring' not on PATH — run: uv tool install keyring --with keyrings.google-artifactregistry-auth"
    fi
    local adc="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/application_default_credentials.json"
    if [ ! -f "$adc" ]; then
        log_status "gcloud_registry: no ADC — run: gcloud auth application-default login"
    fi

    [ "$1" = "--export-token" ] || return 0

    # Optional raw token for consumers without a native lazy helper.
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zon"
    local cache="$cache_dir/gcloud-ar-token"
    local soft=2700 hard=3480 age=99999   # token lifetime ~3600s

    mkdir -p "$cache_dir" && chmod 700 "$cache_dir" 2>/dev/null

    if [ -f "$cache" ]; then
        age=$(( $(date +%s) - $(stat -c %Y "$cache") ))
    fi

    if [ ! -f "$cache" ] || [ "$age" -ge "$hard" ]; then
        # Missing or possibly-expired: refresh synchronously (rare — at most
        # once per machine per hour, and only when genuinely stale).
        _gcloud_ar_refresh "$cache"
    elif [ "$age" -ge "$soft" ]; then
        # Still valid but ageing: serve current token, refresh in background.
        ( _gcloud_ar_refresh "$cache" ) >/dev/null 2>&1 &
        disown 2>/dev/null || true
    fi

    [ -f "$cache" ] && export GOOGLE_AR_ACCESS_TOKEN="$(cat "$cache")"
}

# Atomically (re)write the cached access token. Never leaves a partial file.
_gcloud_ar_refresh() {
    local cache="$1"
    gcloud auth application-default print-access-token > "$cache.tmp" 2>/dev/null \
        && mv "$cache.tmp" "$cache" \
        && chmod 600 "$cache"
}
