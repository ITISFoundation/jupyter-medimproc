# Headless FSL + Synb0 (Optimized)
FROM ubuntu:22.04 as runtime
LABEL maintainer="ordonez"

ENV DEBIAN_FRONTEND=noninteractive
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu \
    HOME=/home/jovyan

RUN useradd --uid ${SC_USER_ID} --shell /bin/bash --create-home --home ${HOME} ${SC_USER_NAME}

COPY common/scripts/install_fsl.sh /tmp/install_fsl.sh
RUN chmod +x /tmp/install_fsl.sh

ENV INSTALL_DIR=${HOME} \
    VENV_DIR=${HOME}/.venv \
    OPTIMIZED=true

RUN /tmp/install_fsl.sh && rm /tmp/install_fsl.sh

# Copy Custom Pipeline Script
COPY pipeline_synb0_disco.sh ${HOME}/synb0-disco/src/pipeline_no_docker.sh
RUN chmod +x ${HOME}/synb0-disco/src/pipeline_no_docker.sh && \
    ln -s ${HOME}/synb0-disco/src/pipeline_no_docker.sh /usr/local/bin/pipeline_no_docker.sh

RUN chown -R ${SC_USER_NAME}:${SC_USER_ID} ${HOME}

ENV FSLDIR=${HOME}/fsl
ENV FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLTCLSH="${FSLDIR}/bin/fsltclsh" \
    FSLWISH="${FSLDIR}/bin/fslwish" \
    LD_LIBRARY_PATH="${FSLDIR}/fslpython/envs/fslpython/lib/:${FSLDIR}/lib:${LD_LIBRARY_PATH}" \
    PATH="${FSLDIR}/share/fsl/bin:${HOME}/.venv/bin:${PATH}" \
    ANTSPATH="${HOME}/ants-2.4.4/bin" \
    PATH="${HOME}/ants-2.4.4/bin:${PATH}"

COPY common/entrypoint.sh /docker/entrypoint.sh
RUN chmod +x /docker/entrypoint.sh

WORKDIR ${HOME}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD [ "/bin/bash" ]
