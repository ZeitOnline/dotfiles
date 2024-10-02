#!/bin/bash

# this wrapper script is used to extract secrets from Vault
# so that access errors don't stop the 'chezmoi' commands
# this way we can loop through all available projects to
# find database credentials for example

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
