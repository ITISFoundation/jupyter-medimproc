#!/bin/bash
set -e

# Default settings
INSTALL_DIR="${INSTALL_DIR:-/usr/local}"
OPTIMIZED="${OPTIMIZED:-false}"

echo "Installing Freesurfer System to ${INSTALL_DIR} (Optimized: ${OPTIMIZED})"

# 1. MRtrix3 Dependencies
apt-get -qq update && apt-get install -yq --no-install-recommends \
    ca-certificates \
    curl \
    dc \
    git \
    wget \
    python3 \
    build-essential \
    g++ \
    libeigen3-dev \
    libfftw3-dev \
    libgl1-mesa-dev \
    libpng-dev \
    libqt5opengl5-dev \
    libqt5svg5-dev \
    libtiff5-dev \
    qtbase5-dev \
    zlib1g-dev \
    tcsh \
    bc \
    libgomp1 \
    perl-modules \
    && rm -rf /var/lib/apt/lists/*

# Ensure python symlink exists (MRtrix3 needs it)
if ! command -v python &> /dev/null; then
    ln -s /usr/bin/python3 /usr/bin/python
fi

# 2. MRtrix3 Installation (Build from source)
cd "${INSTALL_DIR}"
echo "Building MRtrix3..."
git clone https://github.com/MRtrix3/mrtrix3.git
cd mrtrix3
git checkout 3.0.4
./configure
./build -persistent -nopaginate
rm -rf tmp

# 3. ART
echo "Installing ART..."
mkdir -p "${INSTALL_DIR}/art"
cd "${INSTALL_DIR}/art"
curl -fsSL https://osf.io/73h5s/download | tar xz --strip-components 1

# 4. ANTs (Note: FSL base also installs ANTs, but this one uses a different source/method?)
# The base file used: curl -fsSL https://osf.io/yswa4/download | tar xz
# The FSL base used: GitHub Release Zip.
# I will stick to the method from freesurfer_base.Dockerfile to avoid regression.
echo "Installing ANTs (Archive)..."
mkdir -p "${INSTALL_DIR}/ants"
cd "${INSTALL_DIR}/ants"
curl -fsSL https://osf.io/yswa4/download | tar xz --strip-components 1

# 5. Freesurfer
echo "Installing Freesurfer 6.0.0..."
# Freesurfer is expected to be copied from the freesurfer-base stage
# This is much faster than downloading from FTP
if [ ! -d "${INSTALL_DIR}/freesurfer" ]; then
    echo "ERROR: Freesurfer directory not found at ${INSTALL_DIR}/freesurfer"
    echo "Expected to be copied from freesurfer-base Docker stage"
    exit 1
fi
echo "Freesurfer found at ${INSTALL_DIR}/freesurfer"

# 6. Optimization
if [ "$OPTIMIZED" = "true" ]; then
    echo "Optimization already done in Docker multi-stage build (freesurfer-optimized stage)"
    echo "Skipping redundant optimization to avoid layer bloat"
fi

echo "Installation Complete."
