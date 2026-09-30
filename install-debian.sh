#!/usr/bin/env bash
# Install kubectl + minikube + helm on Debian family only. Universal version: install.sh
set -euo pipefail
source /etc/os-release
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
KARCH="amd64"; [ "$(uname -m)" = "aarch64" ] && KARCH="arm64"

$SUDO apt-get update
$SUDO apt-get install -y curl ca-certificates conntrack socat openssl

KVER="${KUBECTL_VERSION:-$(curl -fsSL https://dl.k8s.io/release/stable.txt)}"
curl -fsSLO "https://dl.k8s.io/release/${KVER}/bin/linux/${KARCH}/kubectl"
curl -fsSLO "https://dl.k8s.io/release/${KVER}/bin/linux/${KARCH}/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
chmod +x kubectl; $SUDO install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; rm -f kubectl kubectl.sha256

curl -fsSLo minikube "https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-${KARCH}"
chmod +x minikube; $SUDO install -o root -g root -m 0755 minikube /usr/local/bin/minikube; rm -f minikube

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh; ./get_helm.sh; rm -f get_helm.sh

kubectl version --client; minikube version; helm version
