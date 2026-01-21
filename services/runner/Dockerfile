# ============================================================================
# Import all common builder stages from base Dockerfile
# ============================================================================
ARG COMMON_BASE_IMAGE=common-base:latest
FROM ${COMMON_BASE_IMAGE} AS freesurfer-base
FROM ${COMMON_BASE_IMAGE} AS fsl-builder
FROM ${COMMON_BASE_IMAGE} AS ants-builder
FROM ${COMMON_BASE_IMAGE} AS c3d-builder
FROM ${COMMON_BASE_IMAGE} AS pytorch-builder
FROM ${COMMON_BASE_IMAGE} AS synb0-disco-builder
FROM ${COMMON_BASE_IMAGE} AS mrtrix-art-builder

# ============================================================================
# Stage: Runtime - Headless Runner MedImProc (Full Version)
# ============================================================================
FROM ubuntu:24.04 as runtime
LABEL maintainer="ordonez"
ENV DEBIAN_FRONTEND=noninteractive

# Setup SCU User
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu \
    HOME=/home/jovyan

RUN useradd --uid ${SC_USER_ID} --shell /bin/bash --create-home --home ${HOME} ${SC_USER_NAME}

# Copy all neuroimaging components from builder stages
COPY --from=fsl-builder /opt/medimproc/fsl ${HOME}/fsl
COPY --from=ants-builder /opt/medimproc/ants-2.4.4 ${HOME}/ants-2.4.4
COPY --from=c3d-builder /opt/medimproc/c3d-1.0.0-Linux-x86_64 ${HOME}/c3d-1.0.0-Linux-x86_64
COPY --from=pytorch-builder /opt/medimproc/.venv ${HOME}/.venv
COPY --from=synb0-disco-builder /opt/medimproc/synb0-disco ${HOME}/synb0-disco
COPY --from=mrtrix-art-builder /opt/medimproc/mrtrix3 ${HOME}/mrtrix3
COPY --from=mrtrix-art-builder /opt/medimproc/art ${HOME}/art
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
