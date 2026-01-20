#!/bin/bash
set -e

# Default settings
INSTALL_DIR="${INSTALL_DIR:-/usr/local}"

echo "Setting up Synb0-DISCO pipeline..."

# Check if pipeline script exists
if [ ! -f "/tmp/pipeline_synb0_disco.sh" ]; then
    echo "ERROR: Pipeline script not found at /tmp/pipeline_synb0_disco.sh"
    exit 1
fi

# Create target directory if needed
mkdir -p "${INSTALL_DIR}/synb0-disco/src"

# Copy and make executable
cp /tmp/pipeline_synb0_disco.sh "${INSTALL_DIR}/synb0-disco/src/pipeline_no_docker.sh"
chmod +x "${INSTALL_DIR}/synb0-disco/src/pipeline_no_docker.sh"

# Create symlink for easy access
ln -sf "${INSTALL_DIR}/synb0-disco/src/pipeline_no_docker.sh" /usr/local/bin/pipeline_no_docker.sh

echo "Synb0-DISCO pipeline installed at ${INSTALL_DIR}/synb0-disco/src/pipeline_no_docker.sh"
echo "Symlink created at /usr/local/bin/pipeline_no_docker.sh"
