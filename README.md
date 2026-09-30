# Linux Kubernetes Installer

Universal **kubectl + minikube + helm** installer for **Debian and RHEL families** in one command. Merges and modernizes the old `Kubernetes-Ubuntu` and `Kubernetes-CentOs` repos.

## Supported OS

| Family | Distributions |
|---|---|
| Debian | Debian 11/12, Ubuntu 20.04/22.04/24.04, Linux Mint, Pop!_OS, Kali (via bookworm), Raspbian |
| RHEL | AlmaLinux 8/9/10, Rocky 8/9, RHEL 8/9, CentOS Stream, Fedora, Oracle Linux |
| Arch | amd64 and arm64 |

Minimum lab specs: 2 CPUs, 4 GB RAM, 20 GB disk. KVM/VirtualBox/Docker driver requires virtualization enabled.

## What You Get

- `kubectl` (stable by default, SHA256-verified from `dl.k8s.io`)
- `minikube` (latest by default, from GitHub releases)
- `helm` 3 (via official `get-helm-3` script)
- A running single-node cluster (via `minikube start --driver=docker`)

Requires Docker Engine for `--driver=docker`. Install it first with [linux-docker-installer](https://github.com/asadtahta95/linux-docker-installer).

## Structure

```
linux-kubernetes-installer/
├── install.sh          # universal (recommended)
├── install-debian.sh   # Debian family only
├── install-rhel.sh     # RHEL/Alma family only
├── check-k8s.sh        # verification
├── uninstall.sh        # clean uninstall (keeps Docker by default)
```

## Quick Installation (One Line)

Install Docker first (one time):

```bash
curl -fsSL https://raw.githubusercontent.com/asadtahta95/linux-docker-installer/main/install.sh | bash
```

Then install Kubernetes lab:

```bash
curl -fsSL https://raw.githubusercontent.com/asadtahta95/linux-kubernetes-installer/main/install.sh | bash
```

With sudo if you are not root:

```bash
curl -fsSL https://raw.githubusercontent.com/asadtahta95/linux-kubernetes-installer/main/install.sh | sudo bash
```

Install binaries only, without starting the cluster:

```bash
curl -fsSL https://raw.githubusercontent.com/asadtahta95/linux-kubernetes-installer/main/install.sh | START_MINIKUBE=false bash
```

Custom sizing / versions:

```bash
curl -fsSL https://raw.githubusercontent.com/asadtahta95/linux-kubernetes-installer/main/install.sh | MINIKUBE_CPUS=4 MINIKUBE_MEMORY=8192 KUBECTL_VERSION=v1.30.0 bash
```

## Manual Installation

```bash
git clone https://github.com/asadtahta95/linux-kubernetes-installer.git
cd linux-kubernetes-installer
chmod +x *.sh
./install.sh
./check-k8s.sh
```

## Daily Use

```bash
minikube status
kubectl get nodes
kubectl create deployment hello --image=nginx --port=80
kubectl expose deployment hello --type=NodePort
minikube service hello --url
minikube stop
minikube start --driver=docker
minikube delete
```

Uninstall (keeps Docker):

```bash
./uninstall.sh --delete-cluster
```

## What Changed From The Old Scripts

The old `kubernetes-ubuntu.sh` (2022) and `kubernetes-on-centos.sh` (2022) had these problems, all fixed here:

1. **Deprecated `apt-key add`:** replaced with modern key handling. Old Ubuntu script hard-coded `focal` and fails on 22.04/24.04.
2. **Dead kubectl URL:** `storage.googleapis.com/kubernetes-release/.../stable.txt` is retired. Now uses `dl.k8s.io/release/stable.txt` + SHA256 checksum verification.
3. **No version pinning:** now supports `KUBECTL_VERSION`, `MINIKUBE_VERSION`, `K8S_VERSION` env vars.
4. **Insecure `chmod 666 /var/run/docker.sock`:** removed. Uses proper `docker` group instead.
5. **Blind `minikube start`:** now checks Docker daemon first, passes `--cpus/--memory/--disk-size`, and runs as `$SUDO_USER` so `~/.kube/config` has correct ownership.
6. **Single OS per repo:** merged into one universal `install.sh` with `/etc/os-release` detection (same pattern as `linux-docker-installer`).
7. **`set -euo pipefail`, arch detection (amd64/arm64), `check-k8s.sh`, clean `uninstall.sh`, and CI lint** — none existed before.

## Troubleshooting

- `Exiting due to DRV_AS_ROOT`: do not run `minikube start` as root. Run installer as regular user with sudo, or `minikube start` as your user.
- `Insufficient memory`: raise with `MINIKUBE_MEMORY=6144` or stop other apps. Minimum 4096 recommended.
- `Cannot connect to the Docker daemon`: run `sudo systemctl enable --now docker && newgrp docker`.
- `kubectl: command not found` after install: open a new shell or `export PATH=$PATH:/usr/local/bin`.

## Security

`minikube --driver=docker` runs privileged containers locally. Use it for labs, not for multi-tenant production.

## License

MIT
