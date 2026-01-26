# ============================================================================
# Runtime - Headless Runner MedImProc (Full Version)
# Copies all neuroimaging components from medimproc-common builder stages
# ============================================================================
ARG VERSION=1.3.2
FROM simcore/services/dynamic/medimproc-common:${VERSION} AS common

FROM ubuntu:24.04 AS runtime
LABEL maintainer="ordonez"
ENV DEBIAN_FRONTEND=noninteractive

# Setup SCU User
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu \
    HOME=/home/jovyan

RUN useradd --uid ${SC_USER_ID} --shell /bin/bash --create-home --home ${HOME} ${SC_USER_NAME}

# Copy all neuroimaging components from common-base builder stages
COPY --from=common /opt/medimproc/fsl ${HOME}/fsl
COPY --from=common /opt/freesurfer ${HOME}/freesurfer
COPY --from=common /opt/medimproc/ants-2.4.4 ${HOME}/ants-2.4.4
COPY --from=common /opt/medimproc/c3d-1.0.0-Linux-x86_64 ${HOME}/c3d-1.0.0-Linux-x86_64
COPY --from=common /opt/medimproc/.venv ${HOME}/.venv
COPY --from=common /opt/medimproc/synb0-disco ${HOME}/synb0-disco
COPY --from=common /opt/medimproc/mrtrix3 ${HOME}/mrtrix3
COPY --from=common /opt/medimproc/art ${HOME}/art

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
