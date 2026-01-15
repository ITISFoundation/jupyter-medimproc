# Interactive Jupyter MedImProc (FreeSurfer + FSL)
FROM itisfoundation/jupyter-math:2.0.9 as runtime
LABEL maintainer="ordonez"
USER root

# Set installation environment
ENV INSTALL_DIR=${HOME} \
    VENV_DIR=${HOME}/.venv \
    OPTIMIZED=false

# Install FreeSurfer stack (Layer 1)
COPY common/scripts/install_freesurfer.sh /tmp/install_freesurfer.sh
RUN chmod +x /tmp/install_freesurfer.sh && \
    /tmp/install_freesurfer.sh && \
    rm /tmp/install_freesurfer.sh

# Install FSL stack (Layer 2)
COPY common/scripts/install_fsl.sh /tmp/install_fsl.sh
RUN chmod +x /tmp/install_fsl.sh && \
    /tmp/install_fsl.sh && \
    rm /tmp/install_fsl.sh

# Copy FreeSurfer license
COPY freesurfer_license.txt ${HOME}/freesurfer/license.txt

# Copy custom Synb0 pipeline script
COPY pipeline_synb0_disco.sh ${HOME}/synb0-disco/src/pipeline_no_docker.sh
RUN chmod +x ${HOME}/synb0-disco/src/pipeline_no_docker.sh && \
    ln -s ${HOME}/synb0-disco/src/pipeline_no_docker.sh /usr/local/bin/pipeline_no_docker.sh

# Fix permissions
RUN chown -R 1000:100 ${HOME}

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

USER jovyan
WORKDIR ${HOME}
