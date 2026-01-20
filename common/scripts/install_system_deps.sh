#!/bin/bash
set -e

echo "Installing system dependencies..."

# Install system packages required for MRtrix3, ART, and other tools
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

echo "System dependencies installed successfully."
