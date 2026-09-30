#!/usr/bin/env bash
# Verify kubectl + minikube + helm installation and cluster status.
set -uo pipefail
OK=true

command -v kubectl >/dev/null 2>&1 && kubectl version --client || { echo "kubectl: NOT installed"; OK=false; }
command -v minikube >/dev/null 2>&1 && minikube version || { echo "minikube: NOT installed"; OK=false; }
command -v helm >/dev/null 2>&1 && helm version || { echo "helm: NOT installed"; OK=false; }
command -v docker >/dev/null 2>&1 && docker --version || echo "docker: NOT installed (required for --driver=docker)"

if command -v minikube >/dev/null 2>&1; then
  echo "--- minikube status ---"
  minikube status 2>/dev/null || echo "No running minikube cluster (run: minikube start --driver=docker)"
fi

if command -v kubectl >/dev/null 2>&1; then
  echo "--- kubectl nodes ---"
  kubectl get nodes 2>/dev/null || echo "No reachable cluster."
fi

[ "$OK" = true ] && echo "Status: OK" || { echo "Status: INCOMPLETE"; exit 1; }
