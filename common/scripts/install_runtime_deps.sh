#!/bin/bash
set -e

echo "Installing runtime dependencies for neuroimaging tools..."

# Install runtime dependencies
# - adduser: needed by entrypoint scripts
# - tcsh: required by FreeSurfer
# - perl: required by nu_correct with full core modules
# - bc, dc, libgomp1: required by various neuroimaging tools
apt-get update && apt-get install -y --no-install-recommends \
    adduser \
    tcsh \
    bc \
    libgomp1 \
    perl \
    dc \
    && rm -rf /var/lib/apt/lists/*

echo "Runtime dependencies installed successfully."
