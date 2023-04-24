ARG JUPYTER_MINIMAL_VERSION=lab-3.3.2@sha256:a4bf48221bfa864759e0f248affec3df1af0a68ee3e43dfc7435d84926ec92e8
FROM jupyter/minimal-notebook:${JUPYTER_MINIMAL_VERSION} as base


LABEL maintainer="ordonez"

ENV JUPYTER_ENABLE_LAB="yes"
# autentication is disabled for now

### Install necessary software (FreeSurfer, FSL, etc.)
### Code from https://github.com/the-virtual-brain/tvb-recon/blob/master/docker/software/Dockerfile
#Mrtrix
# RUN apt-get update && apt-get install -y wget git g++ python python-numpy libeigen3-dev zlib1g-dev libqt4-opengl-dev libgl1-mesa-dev libfftw3-dev libtiff5-dev dc
# RUN cd /opt && git clone https://github.com/MRtrix3/mrtrix3.git
# RUN cd /opt/mrtrix3 && export EIGEN_CFLAGS="-isystem /usr/include/eigen3" && ./configure
# RUN cd /opt/mrtrix3 && NUMBER_OF_PROCESSORS=1 ./build

# USER root
ENV HOME="/home/$NB_USER"
USER root
WORKDIR ${HOME}
RUN sudo apt-get update

RUN apt-get install -y wget tcsh bc libgomp1 perl-modules

#FSL
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
RUN echo "" | python fslinstaller.py
# ENV FSLDIR /usr/local/fsl
ENV FSLDIR ${HOME}/fsl
RUN . ${FSLDIR}/etc/fslconf/fsl.sh
ENV PATH ${FSLDIR}/bin:${PATH}

### Install conda and necessary Python packages
## Code from https://fabiorosado.dev/blog/install-conda-in-docker/
RUN apt-get update && apt-get install -y build-essential
RUN apt-get install -y wget && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

### Back at OSPARC - JupyterLab Dockerfile
ENV NOTEBOOK_TOKEN=""
ENV NOTEBOOK_BASE_DIR="$HOME/work"

RUN apt-get update && apt-get install -y --no-install-recommends \
  ffmpeg \
  make \
  dvipng \
  gosu \
  # octave \
  # gnuplot \
  # liboctave-dev \
  bc \
  # ghostscript \
  # texlive-xetex \
  # texlive-fonts-recommended \
  # texlive-latex-recommended \
  # texlive-fonts-extra \
  zip \
  fonts-freefont-otf \
  libboost-all-dev \
  libblas-dev \
  liblapack-dev \
  libopenmpi-dev \
  openmpi-bin \
  gsl-bin \
  libgsl-dev \
  perl \
  libhdf5-dev \
  gfortran && \
  apt-get clean && rm -rf /var/lib/apt/lists/*   

RUN pip --no-cache --quiet install --upgrade \
  pip \
  setuptools \
  wheel

# Service (tvb-recon) specific installation
# --------------------------------------------------------------------

FROM base as build

ENV SC_BUILD_TARGET build

WORKDIR /build

# defines the output of the build
RUN mkdir --parents /build/bin

# Dependencies for compilation
RUN apt-get update && apt-get install -y --no-install-recommends gcc cmake

# Python kernels and Jupyter
# --------------------------------------------------------------------

# FROM base as production

# ENV HOME="/home/$NB_USER"

# USER root

# WORKDIR ${HOME}

# Install kernel in virtual-env

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
# Other requirements (nibabel, pyvista, ...)
COPY --chown=$NB_UID:$NB_GID kernels/python-nibabel/requirements.in ${NOTEBOOK_BASE_DIR}/requirements.in
RUN .venv/bin/pip --no-cache install pip-tools && \
  .venv/bin/pip-compile --build-isolation --output-file ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements.in  && \
  .venv/bin/pip --no-cache install -r ${NOTEBOOK_BASE_DIR}/requirements.txt && \
  rm ${NOTEBOOK_BASE_DIR}/requirements.in
RUN jupyter serverextension enable voila && \
  jupyter server extension enable voila

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg .venv/bin/python -c "import matplotlib.pyplot" && \
  # run fix permissions only once
  fix-permissions /home/$NB_USER

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

### TODO Make that for FSL, Freesurfer, mrtrix3, docker run SYNB0-DISCO...
# # Check that dakota works within the python venv
# ENV PYTHONPATH=$PYTHONPATH:${HOME}/dakota/share/dakota/Python/
# RUN echo 'export PATH="/home/${NB_USER}/.venv/bin:$PATH"' >> "/home/${NB_USER}/.bashrc" && \
#   echo 'PYTHONPATH=$PYTHONPATH:${HOME}/dakota/share/dakota/Python/' >> "/home/${NB_USER}/.bashrc" && \
#   cp -r ${HOME}/dakota/share/dakota/examples/official/gui/analysis_driver_tutorial/complete_python_driver/ ${HOME}/test_dakota/complete_python_driver && \
#   cd ${HOME}/test_dakota/complete_python_driver && \
#   dakota -i CPS.in -o python-driver.out > python-driver.stdout    

WORKDIR ${HOME}

EXPOSE 8888

ENTRYPOINT [ "/bin/bash", "/docker/entrypoint.bash" ]