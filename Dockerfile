ARG JUPYTER_MINIMAL_VERSION=lab-3.3.2@sha256:a4bf48221bfa864759e0f248affec3df1af0a68ee3e43dfc7435d84926ec92e8
FROM jupyter/minimal-notebook:${JUPYTER_MINIMAL_VERSION} as base
LABEL maintainer="ordonez"
ENV JUPYTER_ENABLE_LAB="yes"
# autentication is disabled for now
ENV NOTEBOOK_TOKEN=""
ENV NOTEBOOK_BASE_DIR="$HOME/work"

# ENV HOME="/home/$NB_USER"
# WORKDIR ${HOME}
USER root
RUN sudo apt-get update && apt-get install -y wget tcsh bc libgomp1 perl-modules
RUN pip --no-cache --quiet install --upgrade pip setuptools wheel

# Service (FSL) specific installation
# --------------------------------------------------------------------
FROM base as build
ENV SC_BUILD_TARGET build
ENV HOME="/home/$NB_USER"
WORKDIR ${HOME}
USER root


#FSL
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
RUN echo "" | python fslinstaller.py
# RUN find /user -name "fsl.sh"
ENV FSLDIR ${HOME}/fsl
# RUN find ${FSLDIR} -name "fsl.sh"
RUN . ${FSLDIR}/etc/fslconf/fsl.sh
# ENV PATH ${FSLDIR}/bin:${PATH}
ENV PATH $PATH:${FSLDIR}/bin
RUN printenv PATH
RUN ls ${FSLDIR}
# # download FSL and install it at HOME directory
# ### TODO better download and install at BUILD directory, then copy files over

# RUN apt-get update && apt-get install -y --no-install-recommends \
#   ffmpeg \
#   make \
#   dvipng \
#   gosu \
#   # octave \
#   # gnuplot \
#   # liboctave-dev \
#   bc \
#   # ghostscript \
#   # texlive-xetex \
#   # texlive-fonts-recommended \
#   # texlive-latex-recommended \
#   # texlive-fonts-extra \
#   zip \
#   fonts-freefont-otf \
#   libboost-all-dev \
#   libblas-dev \
#   liblapack-dev \
#   libopenmpi-dev \
#   openmpi-bin \
#   gsl-bin \
#   libgsl-dev \
#   perl \
#   libhdf5-dev \
#   gfortran && \
#   apt-get clean && rm -rf /var/lib/apt/lists/*   

# RUN pip --no-cache --quiet install --upgrade pip setuptools wheel

# Python kernels and Jupyter
# --------------------------------------------------------------------
FROM base as production
### FSL was installed in build; then copy to production. Like in dakota.
USER root
ENV HOME="/home/$NB_USER"
ENV FSLDIR ${HOME}/fsl
COPY --from=build ${FSLDIR} ${FSLDIR}
# ENV PATH ${HOME}/fsl/bin:${PATH}

## Does not seem to work, executing ${FSLDIR}/etc/fslconf/fsl.sh
# RUN cat ${FSLDIR}/etc/fslconf/fsl.sh
# RUN chmod +x ${FSLDIR}/etc/fslconf/fsl.sh && . ${FSLDIR}/etc/fslconf/fsl.sh  

#### Other option would be to set everything by hand (from $FSLDIR/etc/fslconf/fsl.sh )
ENV PATH=$FSLDIR/share/fsl/bin:$PATH
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV FSLTCLSH=$FSLDIR/bin/fsltclsh
ENV FSLWISH=$FSLDIR/bin/fslwish 
ENV FSLGECUDAQ=cuda.q
ENV FSL_LOAD_NIFTI_EXTENSIONS=0
ENV FSL_SKIP_GLOBAL=0
ENV LD_LIBRARY_PATH=$FSLDIR/fslpython/envs/fslpython/lib/

# Install kernel in virtual-env
WORKDIR ${HOME}
RUN python3 -m venv .venv &&\
  .venv/bin/pip --no-cache --quiet install --upgrade pip~=21.3 wheel setuptools &&\
  .venv/bin/pip --no-cache --quiet install ipykernel &&\
  .venv/bin/python -m ipykernel install \
  --user \
  --name "python-nibabel" \
  --display-name "python (nibabel)" \
  && \
  echo y | .venv/bin/python -m jupyter kernelspec uninstall python3 &&\
  .venv/bin/python -m jupyter kernelspec list

## copy and resolve dependecies to be up to date
# Basic math and visualization packages
COPY --chown=$NB_UID:$NB_GID kernels/basic-python-math/requirements.in ${NOTEBOOK_BASE_DIR}/requirements.in
RUN .venv/bin/pip --no-cache install pip-tools && \
  .venv/bin/pip-compile --build-isolation --output-file ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements.in  && \
  .venv/bin/pip --no-cache install -r ${NOTEBOOK_BASE_DIR}/requirements.txt && \
  rm ${NOTEBOOK_BASE_DIR}/requirements.in



### TODO enable again !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Other requirements (nibabel, pyvista, ...)
# COPY --chown=$NB_UID:$NB_GID kernels/python-nibabel/requirements.in ${NOTEBOOK_BASE_DIR}/requirements.in
# RUN .venv/bin/pip --no-cache install pip-tools && \
#   .venv/bin/pip-compile --build-isolation --output-file ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements.in  && \
#   .venv/bin/pip --no-cache install -r ${NOTEBOOK_BASE_DIR}/requirements.txt && \
#   rm ${NOTEBOOK_BASE_DIR}/requirements.in
# RUN jupyter serverextension enable voila && \
#   jupyter server extension enable voila

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg .venv/bin/python -c "import matplotlib.pyplot" 
RUN fix-permissions /home/$NB_USER   # run fix permissions only once

# copy README and CHANGELOG
COPY --chown=$NB_UID:$NB_GID CHANGELOG.md ${NOTEBOOK_BASE_DIR}/CHANGELOG.md
COPY --chown=$NB_UID:$NB_GID README.ipynb ${NOTEBOOK_BASE_DIR}/README.ipynb
# remove write permissions from files which are not supposed to be edited
RUN chmod gu-w ${NOTEBOOK_BASE_DIR}/CHANGELOG.md && \
  chmod gu-w ${NOTEBOOK_BASE_DIR}/requirements.txt

RUN mkdir --parents "/home/${NB_USER}/.virtual_documents" && \
  chown --recursive "$NB_USER" "/home/${NB_USER}/.virtual_documents"
ENV JP_LSP_VIRTUAL_DIR="/home/${NB_USER}/.virtual_documents"

# Copying boot scripts
COPY --chown=$NB_UID:$NB_GID docker /docker

RUN apt-get update && apt-get install -y --no-install-recommends gosu 

COPY --chown=$NB_UID:$NB_GID Fariba_FSL_codes ${NOTEBOOK_BASE_DIR}/Fariba_FSL_codes

WORKDIR ${HOME}

EXPOSE 8888

ENTRYPOINT [ "/bin/bash", "/docker/entrypoint.bash" ]

# CMD [". $FSLDIR/etc/fslconf/fsl.sh && echo 'FSL setup file - correctly executed'"]  
# execute configuration file FSL --- Did not work