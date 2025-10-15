# common ZON environment settings

status is-interactive || exit

# set vault URL
set -xg VAULT_ADDR https://vault.ops.zeit.de/

# prefer local kube config:
set -xg KUBECONFIG ./kube.config:$HOME/.kube/config
