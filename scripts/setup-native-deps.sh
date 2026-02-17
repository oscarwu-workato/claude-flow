#!/usr/bin/env bash
set -euo pipefail

# Setup script for environments that need native build tooling
# (e.g. compiling better-sqlite3).

echo "[setup] detecting OS package manager..."

install_build_tools() {
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
      ca-certificates curl git \
      python3 make g++ pkg-config
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y \
      ca-certificates curl git \
      python3 make gcc-c++ pkgconf-pkg-config
  elif command -v yum >/dev/null 2>&1; then
    yum install -y \
      ca-certificates curl git \
      python3 make gcc-c++ pkgconfig
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache \
      ca-certificates curl git \
      python3 make g++ pkgconf
  else
    echo "[setup] unsupported package manager; install python3/make/g++ manually" >&2
    exit 1
  fi
}


check_registry_access() {
  local registry="${NPM_REGISTRY:-https://registry.npmjs.org}"
  echo "[setup] checking npm registry access: ${registry}"
  npm config set registry "${registry}"

  if ! npm view better-sqlite3 version >/dev/null 2>&1; then
    echo "[setup] cannot access package metadata from ${registry}" >&2
    echo "[setup] set NPM_REGISTRY to your internal mirror and rerun (example: NPM_REGISTRY=https://npm.company.local)" >&2
    exit 2
  fi
}

install_node_modules() {
  if [[ -f package-lock.json ]]; then
    echo "[setup] installing dependencies with npm ci"
    npm ci --include=dev
  else
    echo "[setup] package-lock.json not found; running npm install"
    npm install
  fi
}

verify_runtime() {
  echo "[setup] verifying better-sqlite3 is loadable"
  node -e "require('better-sqlite3'); console.log('better-sqlite3: ok')"

  echo "[setup] verifying vitest is available"
  npx --yes vitest --version

  echo "[setup] done"
}

install_build_tools
check_registry_access
install_node_modules
verify_runtime
