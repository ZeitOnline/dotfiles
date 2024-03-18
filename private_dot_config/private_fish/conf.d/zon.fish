set -x VAULT_ADDR https://vault.ops.zeit.de/
# prefer local kube config:
set -xg KUBECONFIG ./kube.config:$HOME/.kube/config
set -xg CLOUDSDK_PYTHON /opt/homebrew/bin/python3.10
