#!/usr/bin/env bash
#
# Linux Kubernetes Lab Installer - Universal
# Installs: kubectl + minikube + helm on Debian and RHEL families.
# Requires: Docker Engine already installed (use linux-docker-installer) for --driver=docker.
#
# Quick Installation (One Line):
#   curl -fsSL https://raw.githubusercontent.com/asadtahta95/linux-kubernetes-installer/main/install.sh | bash
#
# Options via env:
#   START_MINIKUBE=true|false   (default: true)
#   MINIKUBE_DRIVER=docker      (default: docker)
#   MINIKUBE_CPUS=2 MINIKUBE_MEMORY=4096 MINIKUBE_DISK=20g
#   KUBECTL_VERSION=stable      (or v1.30.0)
#   MINIKUBE_VERSION=latest     (or v1.34.0)
#   K8S_VERSION=stable          (passed to minikube --kubernetes-version)
#
# Examples:
#   curl -fsSL .../install.sh | bash
#   START_MINIKUBE=false ./install.sh
#   MINIKUBE_CPUS=4 MINIKUBE_MEMORY=8192 ./install.sh
#
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

START_MINIKUBE="${START_MINIKUBE:-true}"
MINIKUBE_DRIVER="${MINIKUBE_DRIVER:-docker}"
MINIKUBE_CPUS="${MINIKUBE_CPUS:-2}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-4096}"
MINIKUBE_DISK="${MINIKUBE_DISK:-20g}"
KUBECTL_VERSION="${KUBECTL_VERSION:-stable}"
MINIKUBE_VERSION="${MINIKUBE_VERSION:-latest}"
K8S_VERSION="${K8S_VERSION:-stable}"

[ -f /etc/os-release ] || die "Cannot detect OS: /etc/os-release missing."
# shellcheck disable=SC1091
source /etc/os-release
ID="${ID:-unknown}"
ID_LIKE="${ID_LIKE:-}"

SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || die "Run as root or install sudo first."
fi
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Command '$1' not found."; }
need_cmd curl

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  KARCH="amd64" ;;
  aarch64|arm64) KARCH="arm64" ;;
  *) die "Unsupported architecture: $ARCH (only amd64/arm64)" ;;
esac

IS_DEBIAN=false; IS_RHEL=false
case "$ID" in
  debian|ubuntu|linuxmint|pop|kali|raspbian) IS_DEBIAN=true ;;
  almalinux|rocky|rhel|centos|fedora|ol) IS_RHEL=true ;;
  *)
    [[ "$ID_LIKE" == *"debian"* || "$ID_LIKE" == *"ubuntu"* ]] && IS_DEBIAN=true
    [[ "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* || "$ID_LIKE" == *"centos"* ]] && IS_RHEL=true
    ;;
esac
[ "$IS_DEBIAN" = false ] && [ "$IS_RHEL" = false ] && die "Unsupported OS: ID=$ID. Supported: Debian, Ubuntu, Mint, Pop, Kali, Alma, Rocky, RHEL, CentOS Stream, Fedora."

install_deps() {
  if [ "$IS_DEBIAN" = true ]; then
    log "Installing dependencies via apt..."
    $SUDO apt-get update
    $SUDO apt-get install -y curl ca-certificates conntrack socat openssl
  else
    log "Installing dependencies via dnf/yum..."
    PM=dnf; command -v dnf >/dev/null 2>&1 || PM=yum
    $SUDO $PM install -y curl ca-certificates conntrack socat openssl 2>/dev/null || \
    $SUDO $PM install -y curl ca-certificates socat openssl || true
  fi
}

resolve_kubectl_version() {
  if [ "$KUBECTL_VERSION" = "stable" ]; then
    curl -fsSL https://dl.k8s.io/release/stable.txt
  else
    echo "$KUBECTL_VERSION"
  fi
}

install_kubectl() {
  local ver url
  ver="$(resolve_kubectl_version)"
  log "Installing kubectl $ver ($KARCH)..."
  url="https://dl.k8s.io/release/${ver}/bin/linux/${KARCH}/kubectl"
  curl -fsSLO "$url"
  curl -fsSLO "${url}.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  chmod +x kubectl
  $SUDO install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl kubectl.sha256
  kubectl version --client
}

install_minikube() {
  local url ver="$MINIKUBE_VERSION"
  if [ "$ver" = "latest" ]; then
    url="https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-${KARCH}"
  else
    url="https://github.com/kubernetes/minikube/releases/download/${ver}/minikube-linux-${KARCH}"
  fi
  log "Installing minikube $ver ($KARCH)..."
  curl -fsSLo minikube "$url"
  chmod +x minikube
  $SUDO install -o root -g root -m 0755 minikube /usr/local/bin/minikube
  rm -f minikube
  minikube version
}

install_helm() {
  log "Installing helm 3 via official script..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  rm -f get_helm.sh
  helm version
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    warn "Docker not found. Install it first:"
    warn "  curl -fsSL https://raw.githubusercontent.com/asadtahta95/linux-docker-installer/main/install.sh | bash"
    [ "$START_MINIKUBE" = true ] && [ "$MINIKUBE_DRIVER" = "docker" ] && die "minikube --driver=docker requires Docker."
  else
    if ! $SUDO systemctl is-active --quiet docker 2>/dev/null && ! docker info >/dev/null 2>&1; then
      warn "Docker is installed but the daemon is not running. Starting it..."
      $SUDO systemctl enable --now docker 2>/dev/null || true
    fi
  fi
}

start_cluster() {
  [ "$START_MINIKUBE" = true ] || { log "Skipping minikube start (START_MINIKUBE=false)."; return; }
  log "Starting minikube (driver=$MINIKUBE_DRIVER, cpus=$MINIKUBE_CPUS, memory=$MINIKUBE_MEMORY, disk=$MINIKUBE_DISK)..."
  # Run as the real user when invoked via sudo so kubeconfig lands in the right HOME.
  if [ -n "${SUDO_USER:-}" ]; then
    $SUDO -u "$SUDO_USER" minikube start --driver="$MINIKUBE_DRIVER" --cpus="$MINIKUBE_CPUS" --memory="$MINIKUBE_MEMORY" --disk-size="$MINIKUBE_DISK" --kubernetes-version="$K8S_VERSION"
    $SUDO -u "$SUDO_USER" kubectl get nodes
  else
    minikube start --driver="$MINIKUBE_DRIVER" --cpus="$MINIKUBE_CPUS" --memory="$MINIKUBE_MEMORY" --disk-size="$MINIKUBE_DISK" --kubernetes-version="$K8S_VERSION"
    kubectl get nodes
  fi
}

main() {
  log "Detected OS: ID=$ID LIKE=${ID_LIKE:-none} ARCH=$KARCH"
  install_deps
  check_docker
  install_kubectl
  install_minikube
  install_helm
  start_cluster
  echo ""
  echo "====================================="
  echo " Kubernetes lab ready!"
  echo "====================================="
  echo "kubectl version --client | minikube status | helm version"
}

main "$@"
