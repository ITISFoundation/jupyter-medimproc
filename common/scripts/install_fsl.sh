#!/bin/bash
set -e

# Default settings
INSTALL_DIR="${INSTALL_DIR:-/usr/local}"
VENV_DIR="${VENV_DIR:-/home/jovyan/.venv}"
OPTIMIZED="${OPTIMIZED:-false}"

echo "Installing FSL System to ${INSTALL_DIR} with venv at ${VENV_DIR} (Optimized: ${OPTIMIZED})"

# 1. System Dependencies
apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    wget \
    git \
    python3 \
    python3-venv \
    bc \
    file \
    bzip2 \
    tar \
    && rm -rf /var/lib/apt/lists/*

# 2. FSL Installation
# Uses a temporary directory for the installer
mkdir -p /tmp/fsl_install
cd /tmp/fsl_install
wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
# Run installer
echo "Installing FSL..."
# Note: FSL installer prompts for directory. We pipe echo to it? 
# The original dockerfile used: echo "" | python fslinstaller.py -d ${FSLDIR}
# We need to ensure python is available (Ubuntu might only have python3)
if ! command -v python &> /dev/null; then
    ln -s /usr/bin/python3 /usr/bin/python
fi

FSLDIR="${INSTALL_DIR}/fsl"
echo "" | python fslinstaller.py -d "${FSLDIR}"

# Source config to ensure it works
. "${FSLDIR}/etc/fslconf/fsl.sh"

# 3. Python Environment & Synb0-Disco
# Create venv if it doesn't exist
if [ ! -d "${VENV_DIR}" ]; then
    python3 -m venv "${VENV_DIR}"
fi

# Install PyTorch
${VENV_DIR}/bin/pip --no-cache install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install Synb0-Disco
cd "${INSTALL_DIR}"
echo "Cloning Synb0-DISCO..."
mkdir -p synb0-disco
git clone -b "master" --depth 1 https://github.com/MASILab/Synb0-DISCO "${INSTALL_DIR}/synb0-disco"
rm -rf "${INSTALL_DIR}/synb0-disco/v1_0"

# Setup Permissions/Dirs for Synb0
mkdir -p "${INSTALL_DIR}/synb0-disco/INPUTS"
mkdir -p "${INSTALL_DIR}/synb0-disco/OUTPUTS"
chmod -R 777 "${INSTALL_DIR}/synb0-disco/INPUTS"
chmod -R 777 "${INSTALL_DIR}/synb0-disco/OUTPUTS"

# 4. ANTs
echo "Installing ANTs..."
cd "${INSTALL_DIR}"
curl -SL https://github.com/ANTsX/ANTs/releases/download/v2.4.4/ants-2.4.4-ubuntu-20.04-X64-gcc.zip -o ants.zip
unzip ants.zip
rm ants.zip
# The zip extracts to 'ants-2.4.4', not 'ants-2.4.4-ubuntu-20.04-X64-gcc'
# We saw 'creating: ants-2.4.4/' in the logs.
# So we don't need to move it, or we move it to the final name if we want consistent naming.
# The script previously did: mv ants-2.4.4-ubuntu-20.04-X64-gcc ants-2.4.4
# But logs show it extracted to ants-2.4.4
# So we verify if ants-2.4.4 exists.
if [ -d "ants-2.4.4" ]; then
    echo "ANTs extracted to ants-2.4.4"
elif [ -d "ants-2.4.4-ubuntu-20.04-X64-gcc" ]; then
    mv ants-2.4.4-ubuntu-20.04-X64-gcc ants-2.4.4
fi

# 5. C3D
echo "Installing C3D..."
cd "${INSTALL_DIR}"
curl -SL https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download -o c3d.tar.gz
tar -xzf c3d.tar.gz
rm c3d.tar.gz

# 6. Optimization (Optional)
if [ "$OPTIMIZED" = "true" ]; then
    echo "Running Optimization: Cleaning unnecessary files..."
    rm -rf "${FSLDIR}/data/standard"
    rm -rf "${FSLDIR}/doc"
    rm -rf "${FSLDIR}/extras/src"
    rm -rf "${FSLDIR}/src"
    # Basic cleanup
    rm -rf /tmp/fsl_install
fi

echo "Installation Complete."
