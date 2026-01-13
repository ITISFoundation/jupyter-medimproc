# Interactive FSL + Synb0
FROM itisfoundation/jupyter-math:2.0.9 as runtime
LABEL maintainer="ordonez"
USER root

# Install FSL via Script
COPY common/scripts/install_fsl.sh /tmp/install_fsl.sh
RUN chmod +x /tmp/install_fsl.sh

ENV INSTALL_DIR=${HOME} \
    VENV_DIR=${HOME}/.venv \
    OPTIMIZED=false

RUN /tmp/install_fsl.sh && rm /tmp/install_fsl.sh

# Copy Custom Pipeline Script
COPY pipeline_synb0_disco.sh ${HOME}/synb0-disco/src/pipeline_no_docker.sh
RUN chmod +x ${HOME}/synb0-disco/src/pipeline_no_docker.sh && \
    ln -s ${HOME}/synb0-disco/src/pipeline_no_docker.sh /usr/local/bin/pipeline_no_docker.sh

# Fix permissions
RUN chown -R 1000:100 ${HOME}

# Runtime Env
ENV FSLDIR=${HOME}/fsl
ENV FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLTCLSH="${FSLDIR}/bin/fsltclsh" \
    FSLWISH="${FSLDIR}/bin/fslwish" \
    LD_LIBRARY_PATH="${FSLDIR}/fslpython/envs/fslpython/lib/:${FSLDIR}/lib:${LD_LIBRARY_PATH}" \
    PATH="${FSLDIR}/share/fsl/bin:${HOME}/.venv/bin:${PATH}" \
    ANTSPATH="${HOME}/ants-2.4.4/bin" \
    PATH="${HOME}/ants-2.4.4/bin:${PATH}"

USER jovyan
WORKDIR ${HOME}
