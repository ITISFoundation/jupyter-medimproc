# Interactive Freesurfer
FROM itisfoundation/jupyter-math:2.0.9 as runtime
LABEL maintainer="ordonez"
USER root

COPY common/scripts/install_freesurfer.sh /tmp/install_fs.sh
RUN chmod +x /tmp/install_fs.sh

ENV INSTALL_DIR=${HOME} \
    OPTIMIZED=false

RUN /tmp/install_fs.sh && rm /tmp/install_fs.sh

COPY freesurfer_license.txt ${HOME}/freesurfer/license.txt
RUN chown -R 1000:100 ${HOME}

ENV FREESURFER_HOME=${HOME}/freesurfer \
    ANTSPATH="${HOME}/ants/bin" \
    ARTHOME="${HOME}/art" \
    PATH="${HOME}/mrtrix3/bin:${HOME}/ants/bin:${HOME}/art/bin:${PATH}"

ENV FSFAST_HOME=${FREESURFER_HOME}/fsfast \
    MINC_BIN_DIR=${FREESURFER_HOME}/mni/bin \
    MNI_DIR=${FREESURFER_HOME}/mni \
    PERL5LIB=${FREESURFER_HOME}/mni/share/perl5 \
    PATH=${FREESURFER_HOME}/bin:${MINC_BIN_DIR}:${PATH}

USER jovyan
WORKDIR ${HOME}
