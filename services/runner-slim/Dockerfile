# ============================================================================
# Runtime - Headless Runner MedImProc (Slim/Optimized Version)
# Copies all neuroimaging components from medimproc-common builder stages
# Creates optimized FSL and FreeSurfer in this layer for reduced image size
# ============================================================================
ARG VERSION=1.3.2

# Stage: Optimize FreeSurfer for slim build
FROM simcore/services/dynamic/medimproc-common:${VERSION} AS freesurfer-optimized
RUN cd /opt/freesurfer && \
    # Remove example subjects and data (already done but keep for clarity)
    rm -rf subjects docs && \
    # Remove toolkits not needed for headless structural recon
    rm -rf fsfast trctrain diffusion matlab tktools && \
    # Remove GUI tools (freeview, etc.) - not needed for headless runner
    rm -rf python/packages python/scripts/freeview* python/scripts/tkmedit* && \
    # Remove alternative models/atlases not used in default recon-all
    rm -rf models/DKTatlas* models/ExVivo* && \
    # Clean up docs and license files (keep main license.txt)
    find . -type f -name "README*" -delete 2>/dev/null || true && \
    find . -type f -name "*.pdf" -delete 2>/dev/null || true && \
    echo "FreeSurfer optimized"

# Stage: Optimize FSL for slim build
FROM simcore/services/dynamic/medimproc-common:${VERSION} AS fsl-optimized
RUN cd /opt/medimproc/fsl && \
    # Remove unused data directories (~2.4GB)
    rm -rf data/first data/omm data/xtract_data data/possum data/feat5 doc extras/src src && \
    # Remove FSL Python packages (pipeline uses separate .venv) (~1.5GB)
    rm -rf lib/python3.12/site-packages/scipy lib/python3.12/site-packages/pandas \
           lib/python3.12/site-packages/matplotlib lib/python3.12/site-packages/numpy && \
    # Remove compiler/build tools not needed at runtime (~1GB)
    rm -rf lib/gcc lib/libLLVM* lib/libclang* lib/openvino-* && \
    # Clean Python cache files
    find lib/python3.12 -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find lib/python3.12 -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    echo "FSL optimized"

# Stage: Final runtime
FROM ubuntu:24.04 AS runtime
LABEL maintainer="ordonez"
ENV DEBIAN_FRONTEND=noninteractive

# Setup SCU User
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu \
    HOME=/home/jovyan

RUN useradd --uid ${SC_USER_ID} --shell /bin/bash --create-home --home ${HOME} ${SC_USER_NAME}

# Copy optimized components from optimization stages
COPY --from=fsl-optimized /opt/medimproc/fsl ${HOME}/fsl
COPY --from=freesurfer-optimized /opt/freesurfer ${HOME}/freesurfer

# Copy remaining components from fsl-optimized stage (which has all from medimproc-common)
COPY --from=fsl-optimized /opt/medimproc/ants-2.4.4 ${HOME}/ants-2.4.4
COPY --from=fsl-optimized /opt/medimproc/c3d-1.0.0-Linux-x86_64 ${HOME}/c3d-1.0.0-Linux-x86_64
COPY --from=fsl-optimized /opt/medimproc/.venv ${HOME}/.venv
COPY --from=fsl-optimized /opt/medimproc/synb0-disco ${HOME}/synb0-disco
COPY --from=fsl-optimized /opt/medimproc/mrtrix3 ${HOME}/mrtrix3
COPY --from=fsl-optimized /opt/medimproc/art ${HOME}/art

# Post-installation setup (license, pipeline, permissions)
COPY freesurfer_license.txt /tmp/freesurfer_license.txt
COPY pipeline_synb0_disco.sh /tmp/pipeline_synb0_disco.sh
COPY common/scripts/setup_freesurfer_license.sh /tmp/setup_freesurfer_license.sh
COPY common/scripts/setup_synb0_pipeline.sh /tmp/setup_synb0_pipeline.sh
COPY common/scripts/fix_permissions.sh /tmp/fix_permissions.sh
RUN chmod +x /tmp/setup_freesurfer_license.sh /tmp/setup_synb0_pipeline.sh /tmp/fix_permissions.sh && \
    # TARGET_USER=${SC_USER_NAME} TARGET_GROUP=${SC_USER_ID} TARGET_DIR=${HOME} /tmp/fix_permissions.sh && \
    INSTALL_DIR=${HOME} /tmp/setup_freesurfer_license.sh && \
    /tmp/setup_synb0_pipeline.sh && \
    rm /tmp/setup_freesurfer_license.sh /tmp/setup_synb0_pipeline.sh /tmp/fix_permissions.sh /tmp/freesurfer_license.txt /tmp/pipeline_synb0_disco.sh

# ============================================================================
# ENVIRONMENT VARIABLES - FreeSurfer
# ============================================================================
ENV FREESURFER_HOME=${HOME}/freesurfer \
    ANTSPATH="${HOME}/ants/bin" \
    ARTHOME="${HOME}/art" \
    PATH="${HOME}/mrtrix3/bin:${HOME}/ants/bin:${HOME}/art/bin:${PATH}"

ENV FSFAST_HOME=${FREESURFER_HOME}/fsfast \
    MINC_BIN_DIR=${FREESURFER_HOME}/mni/bin \
    MNI_DIR=${FREESURFER_HOME}/mni \
    PERL5LIB=${FREESURFER_HOME}/mni/share/perl5 \
    PATH=${FREESURFER_HOME}/bin:${MINC_BIN_DIR}:${PATH}

# ============================================================================
# ENVIRONMENT VARIABLES - FSL
# ============================================================================
ENV FSLDIR=${HOME}/fsl \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLTCLSH="${HOME}/fsl/bin/fsltclsh" \
    FSLWISH="${HOME}/fsl/bin/fslwish" \
    LD_LIBRARY_PATH="${HOME}/fsl/fslpython/envs/fslpython/lib/:${HOME}/fsl/lib:${LD_LIBRARY_PATH}" \
    PATH="${HOME}/fsl/share/fsl/bin:${HOME}/.venv/bin:${HOME}/ants-2.4.4/bin:${PATH}"

# ============================================================================
# RUNNER INTEGRATION
# ============================================================================
ENV SC_BUILD_TARGET="runtime" \
    INPUT_FOLDER="/input" \
    OUTPUT_FOLDER="/output"

# Entrypoint
COPY common/entrypoint.sh /docker/entrypoint.sh
RUN chmod +x /docker/entrypoint.sh

# Set environment for MNI tools from FreeSurfer
ENV PATH="/home/jovyan/freesurfer/mni/bin:${PATH}"

# Install adduser for entrypoint script and remove default ubuntu user (avoids UID 1000 conflict)
# Also install runtime dependencies for neuroimaging tools
# - tcsh: required by FreeSurfer
# - perl: required by nu_correct with full core modules
# - bc, dc, libgomp1: required by various neuroimaging tools
RUN apt-get update && apt-get install -y --no-install-recommends adduser tcsh bc libgomp1 perl dc && userdel ubuntu && rm -rf /var/lib/apt/lists/*

WORKDIR ${HOME}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD [ "/bin/bash" ]
