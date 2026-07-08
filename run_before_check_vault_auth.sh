#!/bin/bash

# Warn (but don't fail) when the Vault token is missing or expired.
#
# The secret wrapper (vault.sh) deliberately swallows Vault errors so that
# lacking access to some projects doesn't abort the whole chezmoi run. The
# side effect is that a *fully* expired token silently yields empty configs
# (e.g. ~/.pg_service.conf is never created), with no hint as to why.
#
# This check surfaces that case up front with an actionable message, while
# staying non-fatal so apply still proceeds for anyone who intends to run
# without Vault access.

if ! vault token lookup >/dev/null 2>&1; then
    cat >&2 <<'EOF'

⚠️  Vault authentication is missing or expired.
    Secrets can't be read, so generated files (e.g. ~/.pg_service.conf) will be empty.

    Log in and re-run if needed
EOF
fi

exit 0
