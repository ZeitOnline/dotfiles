#!/bin/bash

command=${1}
shift

case $command in
    get)
        vault kv get -format=json $@ 2> /dev/null || echo 'null'
    ;;
    list)
        vault kv list -format=json $@ 2> /dev/null | sed 's/^{}$/[]/'
    ;;
    *)
        echo "Unrecognized command: $command"
        exit 1
    ;;
esac
