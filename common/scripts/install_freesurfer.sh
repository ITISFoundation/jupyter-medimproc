#!/bin/bash
set -e

# Default settings
INSTALL_DIR="${INSTALL_DIR:-/usr/local}"
OPTIMIZED="${OPTIMIZED:-false}"

echo "Installing Freesurfer System to ${INSTALL_DIR} (Optimized: ${OPTIMIZED})"

# 1. MRtrix3 Dependencies
apt-get -qq update && apt-get install -yq --no-install-recommends \
    curl \
    dc \
    git \
    wget \
    python3 \
    libeigen3-dev \
    libfftw3-dev \
    libgl1-mesa-dev \
    libpng-dev \
    libqt5opengl5-dev \
    libqt5svg5-dev \
    libtiff5-dev \
    qt5-default \
    zlib1g-dev \
    tcsh \
    bc \
    libgomp1 \
    perl-modules \
    && rm -rf /var/lib/apt/lists/*

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
cd "${INSTALL_DIR}"
# Note: The FTP link can be slow.
wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz | tar -xzv
# The tarball expands to 'freesurfer' directory in current dir.
# So we have ${INSTALL_DIR}/freesurfer

# 6. Optimization
if [ "$OPTIMIZED" = "true" ]; then
    echo "Running Optimization..."
    FS_HOME="${INSTALL_DIR}/freesurfer"
    rm -rf "${FS_HOME}/subjects"
    # Wait, the comment said "we actually need subjects/fsaverage". 
    # If I remove 'subjects', I might break things.
    # But the optimization request earlier (in previous turn) had explicit rm -rf subjects.
    # The user accepted that logic. But it's risky.
    # I will be safer and keep 'fsaverage' if possible?
    # Or just stick to the requested "rm -rf subjects" if that's what the 'min' dockerfile did.
    # The 'min' dockerfile diff earlier showed: rm -rf /usr/local/freesurfer/subjects
    # So I will replicate that.
    
    rm -rf "${FS_HOME}/docs"
    rm -rf "${FS_HOME}/trctrain"
    rm -rf "${FS_HOME}/diffusion"
    rm -rf "${FS_HOME}/matlab"
fi

echo "Installation Complete."
