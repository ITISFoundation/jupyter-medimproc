# ============================================================================
# Stage 1: Extract FreeSurfer from official image (Full Version)
# ============================================================================
FROM freesurfer/freesurfer:6.0 as freesurfer-base

# ============================================================================
# Stage 2: Shared MedImProc Base (Common to all variants)
# This stage installs all neuroimaging software to /opt/medimproc
# to enable layer sharing across jupyter, runner, and runner-slim variants
# ============================================================================
FROM ubuntu:24.04 as medimproc-common-base
LABEL maintainer="ordonez"
ENV DEBIAN_FRONTEND=noninteractive

# Set installation paths to shared location (not user-specific)
ENV INSTALL_DIR=/opt/medimproc \
    VENV_DIR=/opt/medimproc/.venv \
    OPTIMIZED=false

# Install neuroimaging tools (MRtrix3, ART) and their dependencies
COPY common/scripts/install_system_deps.sh /tmp/install_system_deps.sh
COPY common/scripts/install_mrtrix3.sh /tmp/install_mrtrix3.sh
COPY common/scripts/install_art.sh /tmp/install_art.sh
RUN chmod +x /tmp/install_system_deps.sh /tmp/install_mrtrix3.sh /tmp/install_art.sh && \
    /tmp/install_system_deps.sh && \
    /tmp/install_mrtrix3.sh && \
    /tmp/install_art.sh && \
    rm /tmp/install_system_deps.sh /tmp/install_mrtrix3.sh /tmp/install_art.sh

# Install FSL stack (largest layer ~8-10GB - want to share this!)
COPY common/scripts/install_fsl.sh /tmp/install_fsl.sh
RUN chmod +x /tmp/install_fsl.sh && \
    /tmp/install_fsl.sh && \
    rm /tmp/install_fsl.sh

# ============================================================================
# Stage 3: Runtime - Headless Runner MedImProc (Full Version)
# ============================================================================
FROM ubuntu:24.04 as runtime
LABEL maintainer="ordonez"
ENV DEBIAN_FRONTEND=noninteractive

# Setup SCU User
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu \
    HOME=/home/jovyan

RUN useradd --uid ${SC_USER_ID} --shell /bin/bash --create-home --home ${HOME} ${SC_USER_NAME}

# Copy all neuroimaging software from shared base
COPY --from=medimproc-common-base /opt/medimproc ${HOME}/
# Copy FreeSurfer from official image (much faster than FTP download)
COPY --from=freesurfer-base /opt/freesurfer ${HOME}/freesurfer

# Post-installation setup (license, pipeline, permissions)
COPY freesurfer_license.txt /tmp/freesurfer_license.txt
COPY pipeline_synb0_disco.sh /tmp/pipeline_synb0_disco.sh
COPY common/scripts/setup_freesurfer_license.sh /tmp/setup_freesurfer_license.sh
COPY common/scripts/setup_synb0_pipeline.sh /tmp/setup_synb0_pipeline.sh
COPY common/scripts/fix_permissions.sh /tmp/fix_permissions.sh
RUN chmod +x /tmp/setup_freesurfer_license.sh /tmp/setup_synb0_pipeline.sh /tmp/fix_permissions.sh && \
    TARGET_USER=${SC_USER_NAME} TARGET_GROUP=${SC_USER_ID} TARGET_DIR=${HOME} /tmp/fix_permissions.sh && \
    /tmp/setup_freesurfer_license.sh && \
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

WORKDIR ${HOME}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD [ "/bin/bash" ]
