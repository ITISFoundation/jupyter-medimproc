#!/bin/bash
set -e

# Default settings
INSTALL_DIR="${INSTALL_DIR:-/usr/local}"

echo "Building MRtrix3..."

cd "${INSTALL_DIR}"
git clone https://github.com/MRtrix3/mrtrix3.git
cd mrtrix3
git checkout 3.0.4
./configure
./build -persistent -nopaginate
rm -rf tmp

echo "MRtrix3 installed successfully at ${INSTALL_DIR}/mrtrix3"
