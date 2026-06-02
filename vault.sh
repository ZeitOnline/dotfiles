#!/bin/bash

# this wrapper script is used to extract secrets from Vault
# so that access errors don't stop the 'chezmoi' commands
# this way we can loop through all available projects to
# find database credentials for example

_sentinel="${TMPDIR:-/tmp}/vault-auth-check.${PPID}"
if [[ ! -f "$_sentinel" ]]; then
    if ! vault token lookup > /dev/null 2>&1; then
        echo "vault: not authenticated — run 'vault login' first" >&2
        exit 1
    fi
    touch "$_sentinel"
fi

command=${1}
shift

case $command in
    get)
        vault kv get -format=json $@ 2> /dev/null || echo 'null'
    ;;
    list)
        output="$( vault kv list -format=json $@ 2> /dev/null | sed '/^{}$/d' )"
        echo "${output:-[]}"
    ;;
    *)
        echo "Unrecognized command: $command"
        exit 1
    ;;
esac
