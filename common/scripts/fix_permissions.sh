#!/bin/bash
set -e

# Default settings
TARGET_USER="${TARGET_USER:-jovyan}"
TARGET_GROUP="${TARGET_GROUP:-users}"
TARGET_DIR="${TARGET_DIR:-/home/jovyan}"

echo "Fixing permissions for ${TARGET_DIR}..."
echo "Owner will be set to ${TARGET_USER}:${TARGET_GROUP}"

# Fix ownership
chown -R "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_DIR}"

echo "Permissions fixed successfully"
