# Headless Freesurfer (Standard)
FROM ubuntu:22.04 as runtime
LABEL maintainer="ordonez"
ENV DEBIAN_FRONTEND=noninteractive

# Setup SCU User
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu \
    HOME=/home/jovyan

RUN useradd --uid ${SC_USER_ID} --shell /bin/bash --create-home --home ${HOME} ${SC_USER_NAME}

# Install Freesurfer + Tools
COPY common/scripts/install_freesurfer.sh /tmp/install_fs.sh
RUN chmod +x /tmp/install_fs.sh

ENV INSTALL_DIR=${HOME} \
    OPTIMIZED=false

RUN /tmp/install_fs.sh && rm /tmp/install_fs.sh

# License (Must be in build context)
COPY freesurfer_license.txt ${HOME}/freesurfer/license.txt

# Fix permissions
RUN chown -R ${SC_USER_NAME}:${SC_USER_ID} ${HOME}

# Runtime Env
ENV FREESURFER_HOME=${HOME}/freesurfer \
    ANTSPATH="${HOME}/ants/bin" \
    ARTHOME="${HOME}/art" \
    PATH="${HOME}/mrtrix3/bin:${HOME}/ants/bin:${HOME}/art/bin:${PATH}"

ENV FSFAST_HOME=${FREESURFER_HOME}/fsfast \
    MINC_BIN_DIR=${FREESURFER_HOME}/mni/bin \
    MNI_DIR=${FREESURFER_HOME}/mni \
    PERL5LIB=${FREESURFER_HOME}/mni/share/perl5 \
    PATH=${FREESURFER_HOME}/bin:${MINC_BIN_DIR}:${PATH}

# Entrypoint
COPY common/entrypoint.sh /docker/entrypoint.sh
RUN chmod +x /docker/entrypoint.sh

WORKDIR ${HOME}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD [ "/bin/bash" ]
