# Service (FSL) specific installation
# --------------------------------------------------------------------
FROM itisfoundation/jupyter-math:2.0.8 as base
LABEL maintainer="ordonez"
USER root

#FSL
ENV FSLDIR ${HOME}/fsl
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
RUN echo "" | python fslinstaller.py
# ENV FSLDIR ${HOME}/fsl
# ENV FSLDIR /root/fsl
# RUN . ${FSLDIR}/etc/fslconf/fsl.sh
# RUN . /root/fsl/etc/fslconf/fsl.sh
RUN . ${FSLDIR}/etc/fslconf/fsl.sh
# ENV PATH $PATH:${FSLDIR}/bin


# ARG JUPYTER_MINIMAL_VERSION=lab-3.3.2@sha256:a4bf48221bfa864759e0f248affec3df1af0a68ee3e43dfc7435d84926ec92e8
# FROM jupyter/minimal-notebook:${JUPYTER_MINIMAL_VERSION} as production



### Copy the installed FSL to the production image
ENV FSLDIR ${HOME}/fsl
# COPY --from=install_fsl_container /root/fsl ${FSLDIR}

### Set all necessary FSL environment variables
ENV PATH=$FSLDIR/share/fsl/bin:$PATH
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV FSLTCLSH=$FSLDIR/bin/fsltclsh
ENV FSLWISH=$FSLDIR/bin/fslwish 
ENV FSLGECUDAQ=cuda.q
ENV FSL_LOAD_NIFTI_EXTENSIONS=0
ENV FSL_SKIP_GLOBAL=0
ENV LD_LIBRARY_PATH=$FSLDIR/fslpython/envs/fslpython/lib/

# copy and resolve dependecies to be up to date
COPY --chown=$NB_UID:$NB_GID requirements.in ${NOTEBOOK_BASE_DIR}/requirements.in
RUN .venv/bin/pip --no-cache install pip-tools && \
  ## rename the previously existing "requirements.txt" from the jupyter-math service (we want to keep it for user reference)
  mv ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements_base_math.txt &&\
  .venv/bin/pip-compile --build-isolation --output-file ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements.in  && \
  .venv/bin/pip --no-cache install -r ${NOTEBOOK_BASE_DIR}/requirements.txt && \
  rm ${NOTEBOOK_BASE_DIR}/requirements.in && \
  echo "Your environment contains these python packages:" && \
  .venv/bin/pip list 

# remove write permissions from files which are not supposed to be edited
RUN chmod gu-w ${NOTEBOOK_BASE_DIR}/requirements_base_math.txt &&\
  chmod gu-w ${NOTEBOOK_BASE_DIR}/requirements.txt

## change the name of the kernel (just for display) in the kernel JSON file
ENV PYTHON_KERNEL_NAME="python (nibabel)"
ENV KERNEL_DIR ${HOME}/.local/share/jupyter/kernels/python-maths
RUN sudo apt update && sudo apt install -y jq &&\
  jq --arg a "$PYTHON_KERNEL_NAME" '.display_name = $a' ${KERNEL_DIR}/kernel.json > ${KERNEL_DIR}/temp.json \
  && mv ${KERNEL_DIR}/temp.json ${KERNEL_DIR}/kernel.json

## Modified README file, to include info about FSL
COPY --chown=$NB_UID:$NB_GID README.ipynb ${NOTEBOOK_BASE_DIR}/README.ipynb

## TEMP : for testing
COPY --chown=$NB_UID:$NB_GID Fariba_FSL_codes ${NOTEBOOK_BASE_DIR}/Fariba_FSL_codes


EXPOSE 8888

ENTRYPOINT [ "/bin/bash", "/docker/entrypoint.bash" ]