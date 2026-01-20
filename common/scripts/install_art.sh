#!/bin/bash
set -e

# Default settings
INSTALL_DIR="${INSTALL_DIR:-/usr/local}"

echo "Installing ART (Automatic Registration Toolbox)..."

mkdir -p "${INSTALL_DIR}/art"
cd "${INSTALL_DIR}/art"
curl -fsSL https://osf.io/73h5s/download | tar xz --strip-components 1

echo "ART installed successfully at ${INSTALL_DIR}/art"
