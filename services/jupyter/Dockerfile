# ============================================================================
# Runtime - Interactive Jupyter MedImProc (Full Version)
# Copies all neuroimaging components from medimproc-common builder stages
# ============================================================================
FROM simcore/services/dynamic/medimproc-common:0.0.0 AS common

FROM itisfoundation/jupyter-math:2.0.9 AS runtime
LABEL maintainer="ordonez"
USER root

# Install runtime dependencies
COPY common/scripts/install_runtime_deps.sh /tmp/install_runtime_deps.sh
RUN chmod +x /tmp/install_runtime_deps.sh && \
    /tmp/install_runtime_deps.sh && \
    rm /tmp/install_runtime_deps.sh

# Copy all neuroimaging components from common-base builder stages
COPY --from=common /opt/medimproc/fsl ${HOME}/fsl
COPY --from=common /opt/medimproc/ants-2.4.4 ${HOME}/ants-2.4.4
COPY --from=common /opt/medimproc/c3d-1.0.0-Linux-x86_64 ${HOME}/c3d-1.0.0-Linux-x86_64
COPY --from=common /opt/medimproc/.venv ${HOME}/.venv
COPY --from=common /opt/medimproc/synb0-disco ${HOME}/synb0-disco
COPY --from=common /opt/medimproc/mrtrix3 ${HOME}/mrtrix3
COPY --from=common /opt/medimproc/art ${HOME}/art
COPY --from=common --chown=jovyan:users /opt/medimproc/sct /opt/medimproc/sct
# Copy FreeSurfer from official image (much faster than FTP download)
COPY --from=common /opt/freesurfer ${HOME}/freesurfer

# Post-installation setup (license, pipeline)
COPY freesurfer_license.txt /tmp/freesurfer_license.txt
COPY pipeline_synb0_disco.sh /tmp/pipeline_synb0_disco.sh
COPY common/scripts/setup_freesurfer_license.sh /tmp/setup_freesurfer_license.sh
COPY common/scripts/setup_synb0_pipeline.sh /tmp/setup_synb0_pipeline.sh
RUN chmod +x /tmp/setup_freesurfer_license.sh /tmp/setup_synb0_pipeline.sh && \
    INSTALL_DIR=${HOME} /tmp/setup_freesurfer_license.sh && \
    INSTALL_DIR=${HOME} /tmp/setup_synb0_pipeline.sh && \
    rm /tmp/setup_freesurfer_license.sh /tmp/setup_synb0_pipeline.sh /tmp/freesurfer_license.txt /tmp/pipeline_synb0_disco.sh

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
# ENVIRONMENT VARIABLES - Spinal Cord Toolbox
# ============================================================================
ENV SCT_DIR=/opt/medimproc/sct \
    PATH="/opt/medimproc/sct/bin:${PATH}"

USER jovyan
WORKDIR ${HOME}
