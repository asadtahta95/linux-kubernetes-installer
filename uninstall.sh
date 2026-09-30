#!/usr/bin/env bash
# Clean uninstall for the Kubernetes lab (keeps Docker by default).
# Usage: ./uninstall.sh [--delete-cluster] [--remove-docker]
set -euo pipefail
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

DELETE_CLUSTER=false; REMOVE_DOCKER=false
for arg in "$@"; do
  case "$arg" in
    --delete-cluster) DELETE_CLUSTER=true ;;
    --remove-docker) REMOVE_DOCKER=true ;;
  esac
done

if command -v minikube >/dev/null 2>&1 && [ "$DELETE_CLUSTER" = true ]; then
  minikube delete || true
fi

$SUDO rm -f /usr/local/bin/kubectl /usr/bin/kubectl
$SUDO rm -f /usr/local/bin/minikube /usr/bin/minikube
$SUDO rm -f /usr/local/bin/helm /usr/bin/helm
rm -rf "${HOME}/.minikube" "${HOME}/.kube" || true

if [ "$REMOVE_DOCKER" = true ] && [ -x ../linux-docker-installer/uninstall.sh ]; then
  ../linux-docker-installer/uninstall.sh
fi

echo "[OK] Kubernetes lab removed. Docker kept (use --remove-docker to remove it too)."
