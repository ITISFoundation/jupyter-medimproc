# syntax=docker/dockerfile:1.4

## Multi-stage build: use FreeSurfer official Docker image to avoid slow server downloads
FROM freesurfer/freesurfer:7.4.1@sha256:10b6468cbd9fcd2db3708f4651d59ad75d4da849a2c5d8bb6dba217f08b8c46b as freesurfer-source

## Main build stage
FROM itisfoundation/jupyter-math:2.0.9 as main
LABEL maintainer="ordonez"
USER root

############################################################
## MRtrix3 v3.0.4 with minified ANTs 2.3.4-2 and ART ACPCdetect
WORKDIR ${HOME}
RUN apt-get -qq update && \
    apt-get install -yq --no-install-recommends \
        curl \
        dc \
        git \
        libeigen3-dev \
        libfftw3-dev \
        libgl1-mesa-dev \
        libpng-dev \
        libqt5opengl5-dev \
        libqt5svg5-dev \
        libtiff5-dev \
        qt5-default \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* && \
    # Clone and build MRtrix3 (shallow clone, remove .git)
    git clone --depth 1 --branch 3.0.4 https://github.com/MRtrix3/mrtrix3.git && \
    cd mrtrix3 && \
    ./configure && \
    ./build -persistent -nopaginate && \
    rm -rf tmp .git && \
    cd ${HOME} && \
    # Download and extract ART ACPCdetect (minified v2.0)
    mkdir -p art && \
    curl -fsSL https://osf.io/73h5s/download | tar xz -C art --strip-components 1 && \
    # Download and extract minified ANTs 2.3.4-2 for MRtrix3
    mkdir -p ants && \
    curl -fsSL https://osf.io/yswa4/download | tar xz -C ants --strip-components 1

ENV ANTSPATH="$HOME/ants/bin" \
    ARTHOME="$HOME/art" \
    PATH="$HOME/mrtrix3/bin:$HOME/ants/bin:$HOME/art/bin:$PATH"

############################################################
## FreeSurfer v7.4.1 (copied from official Docker image to avoid slow downloads)
WORKDIR ${HOME}
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bc \
        libgomp1 \
        perl-modules \
        tcsh && \
    rm -rf /var/lib/apt/lists/*

# Copy FreeSurfer installation from official Docker image
COPY --from=freesurfer-source /usr/local/freesurfer /usr/local/freesurfer

# Set up FreeSurfer environment variables
ENV FREESURFER_HOME=/usr/local/freesurfer/7.4.1 \
    FSFAST_HOME=/usr/local/freesurfer/7.4.1/fsfast \
    MINC_BIN_DIR=/usr/local/freesurfer/7.4.1/mni/bin \
    MNI_DIR=/usr/local/freesurfer/7.4.1/mni \
    PERL5LIB=/usr/local/freesurfer/7.4.1/mni/share/perl5 \
    PATH=$FREESURFER_HOME/bin:$MINC_BIN_DIR:$PATH

# Copy license file to FreeSurfer home (v7 method)
COPY freesurfer_license.txt $FREESURFER_HOME/license.txt

############################################################
## FSL (installed via official installer)
WORKDIR ${HOME}
ENV FSLDIR=${HOME}/fsl \
    FSLOUTPUTTYPE="NIFTI_GZ"

RUN wget -q https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
    echo "" | python fslinstaller.py -d ${FSLDIR} && \
    . ${FSLDIR}/etc/fslconf/fsl.sh && \
    rm -f fslinstaller.py

ENV FSLTCLSH="$FSLDIR/bin/fsltclsh" \
    FSLWISH="$FSLDIR/bin/fslwish" \
    LD_LIBRARY_PATH="$FSLDIR/fslpython/envs/fslpython/lib:$FSLDIR/lib:$LD_LIBRARY_PATH" \
    PATH="$FSLDIR/share/fsl/bin:$PATH"

#############################################################################
## (non-containerized) Synb0-DISCO with PyTorch (CPU), ANTs 2.4.4, and c3d

WORKDIR ${HOME}

# Install PyTorch (CPU), clone Synb0-DISCO, install ANTs and c3d in single layer
RUN --mount=type=cache,target=/root/.cache/pip \
    .venv/bin/pip install \
        torch==2.1.2 \
        torchvision==0.16.2 \
        torchaudio==2.1.2 \
        --index-url https://download.pytorch.org/whl/cpu && \
    # Clone Synb0-DISCO (shallow, remove .git and unused v1_0)
    git clone --depth 1 -b master https://github.com/MASILab/Synb0-DISCO ${HOME}/synb0-disco && \
    rm -rf ${HOME}/synb0-disco/.git ${HOME}/synb0-disco/v1_0 && \
    # Create input/output directories with proper permissions
    mkdir -p synb0-disco/INPUTS synb0-disco/OUTPUTS && \
    chmod -R gua+rwx synb0-disco/INPUTS synb0-disco/OUTPUTS && \
    # Create symbolic link for normalize_T1.sh
    ln -s ${HOME}/synb0-disco/data_processing/normalize_T1.sh /usr/local/bin && \
    # Download and extract ANTs 2.4.4 (for Synb0-DISCO)
    curl -fsSL https://github.com/ANTsX/ANTs/releases/download/v2.4.4/ants-2.4.4-ubuntu-20.04-X64-gcc.zip -o ants.zip && \
    unzip -q ants.zip && \
    rm -f ants.zip && \
    # Download and extract c3d (Convert3D)
    curl -fsSL https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download | tar xz && \
    # Modify inference.py to use CPU instead of GPU
    sed -i '83s/.*/    device = torch.device("cpu")/' ${HOME}/synb0-disco/src/inference.py && \
    sed -i '87s/.*/    model.load_state_dict(torch.load(model_path, map_location=torch.device("cpu")))/' ${HOME}/synb0-disco/src/inference.py

# Set up environment for Synb0-DISCO
ENV PIPELINE_PATH=${HOME}/synb0-disco/src \
    PATH="$PATH:$HOME/ants-2.4.4/bin:$HOME/c3d-1.0.0-Linux-x86_64/bin" \
    ANTSPATH="$HOME/ants-2.4.4/bin/"

# Copy custom pipeline script (wo docker) and create synb0-disco command
COPY --chown=$NB_UID:$NB_GID pipeline_synb0_disco.sh ${PIPELINE_PATH}/pipeline_no_docker.sh
RUN ln -sf ${PIPELINE_PATH}/pipeline_no_docker.sh /usr/local/bin/synb0-disco && \
    chmod +x /usr/local/bin/synb0-disco 

### Temporarily removed for GitHub building space issues
# ############################################################
# ## Spinal Cord Toolbox (command line)
# # RUN apt update && apt-get install -y curl   ## already installed for MRTrix3 
# WORKDIR ${HOME}
# RUN curl --location https://github.com/neuropoly/spinalcordtoolbox/archive/4.2.1.tar.gz | gunzip | tar x &&\
#   cd spinalcordtoolbox-4.2.1 && (yes "y" 2>/dev/null || true) | ./install_sct && cd - && rm -rf spinalcordtoolbox-4.2.1

############################################################
## Python packages: wxPython, attrdict, and requirements.in packages
WORKDIR ${HOME}

# Install wxPython and attrdict
RUN --mount=type=cache,target=/root/.cache/pip \
    .venv/bin/pip install \
        -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-20.04 \
        wxpython && \
    .venv/bin/pip install attrdict

# Install requirements.in packages (nibabel, pyvista, PyOpenGL, fsleyes, connected-components-3d)
COPY --chown=$NB_UID:$NB_GID requirements.in ${NOTEBOOK_BASE_DIR}/requirements.in
RUN --mount=type=cache,target=/root/.cache/pip \
    .venv/bin/pip install pip-tools && \
    # Rename base jupyter-math requirements for reference
    mv ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements_base_math.txt && \
    # Compile and install requirements
    .venv/bin/pip-compile --build-isolation --output-file ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements.in && \
    .venv/bin/pip install -r ${NOTEBOOK_BASE_DIR}/requirements.txt && \
    rm ${NOTEBOOK_BASE_DIR}/requirements.in && \
    echo "Installed Python packages:" && \
    .venv/bin/pip list 

#############################################################################
## Jupyter kernel customization and final setup
ENV PYTHON_KERNEL_NAME="python (Medical Image Processing)"
ENV KERNEL_DIR=${HOME}/.local/share/jupyter/kernels/python-maths

RUN apt-get update && \
    apt-get install -y --no-install-recommends jq && \
    rm -rf /var/lib/apt/lists/* && \
    # Update kernel display name
    jq --arg a "$PYTHON_KERNEL_NAME" '.display_name = $a' ${KERNEL_DIR}/kernel.json > ${KERNEL_DIR}/temp.json && \
    mv ${KERNEL_DIR}/temp.json ${KERNEL_DIR}/kernel.json && \
    # Remove write permissions from requirements files
    chmod gu-w ${NOTEBOOK_BASE_DIR}/requirements_base_math.txt ${NOTEBOOK_BASE_DIR}/requirements.txt

## Copy modified README with FSL information
COPY --chown=$NB_UID:$NB_GID README.ipynb ${NOTEBOOK_BASE_DIR}/README.ipynb

EXPOSE 8888

ENTRYPOINT [ "/bin/bash", "/docker/entrypoint.bash" ]