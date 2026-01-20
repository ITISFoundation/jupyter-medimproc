#!/bin/bash
set -e

# Default settings
INSTALL_DIR="${INSTALL_DIR:-/usr/local}"

echo "Setting up FreeSurfer license..."

# Check if FreeSurfer directory exists
if [ ! -d "${INSTALL_DIR}/freesurfer" ]; then
    echo "ERROR: FreeSurfer directory not found at ${INSTALL_DIR}/freesurfer"
    exit 1
fi

# Check if license file exists in expected location
if [ ! -f "/tmp/freesurfer_license.txt" ]; then
    echo "ERROR: FreeSurfer license file not found at /tmp/freesurfer_license.txt"
    exit 1
fi

# Copy license to FreeSurfer directory
cp /tmp/freesurfer_license.txt "${INSTALL_DIR}/freesurfer/license.txt"
echo "FreeSurfer license installed at ${INSTALL_DIR}/freesurfer/license.txt"
