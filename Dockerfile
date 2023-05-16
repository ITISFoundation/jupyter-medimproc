## Refactor as normal (ie no multistage) dockerfile
## also have a smaller base image
FROM itisfoundation/jupyter-math:2.0.8 as main
LABEL maintainer="ordonez"
USER root

############################################################
## MRtrix(3)
RUN apt-get -qq update \
  && apt-get install -yq --no-install-recommends \
  curl \
  libeigen3-dev \
  libfftw3-dev \
  libgl1-mesa-dev \
  libpng-dev \
  libqt5opengl5-dev \
  libqt5svg5-dev \
  libtiff5-dev \
  qt5-default \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR ${HOME}/mrtrix3
RUN git clone -b "master" --depth 1 https://github.com/MRtrix3/mrtrix3.git . \
  && ./configure "" && NUMBER_OF_PROCESSORS=4 ./build -persistent -nopaginate \
  && rm -rf tmp

WORKDIR ${HOME}/art
RUN curl -fsSL https://osf.io/73h5s/download \
  | tar xz --strip-components 1

WORKDIR ${HOME}/ants
RUN curl -fsSL https://osf.io/yswa4/download \
  | tar xz --strip-components 1

ENV ANTSPATH="$HOME/ants/bin" \
  ARTHOME="$HOME/art" \
  PATH="$HOME/mrtrix3/bin:$HOME/ants/bin:$HOME/art/bin:$PATH"

############################################################
## Freesurfer
WORKDIR ${HOME}
RUN apt-get update && apt-get install -y tcsh bc libgomp1 perl-modules \
  && rm -rf /var/lib/apt/lists/*
RUN wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz | tar -xzv -C ${HOME} \
  && rm -rf ${HOME}/freesurfer/subjects
ENV FREESURFER_HOME ${HOME}/freesurfer
COPY freesurfer_license.txt ${FREESURFER_HOME}/license.txt
ENV FSFAST_HOME==$FREESURFER_HOME/fsfast \
  MINC_BIN_DIR=$FREESURFER_HOME/mni/bin \
  MNI_DIR=$FREESURFER_HOME/mni \
  PERL5LIB=$FREESURFER_HOME/mni/share/perl5
ENV PATH=$FREESURFER_HOME/bin:$MINC_BIN_DIR:$PATH

############################################################
## FSL
WORKDIR ${HOME}
ENV FSLDIR ${HOME}/fsl
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py &&\ 
  echo "" | python fslinstaller.py -d ${FSLDIR} &&\ 
  . ${FSLDIR}/etc/fslconf/fsl.sh
ENV FSLOUTPUTTYPE="NIFTI_GZ" \
  FSLTCLSH="$FSLDIR/bin/fsltclsh" \
  FSLWISH="$FSLDIR/bin/fslwish" \
  LD_LIBRARY_PATH=$FSLDIR/fslpython/envs/fslpython/lib/ \
  LD_LIBRARY_PATH="$FSLDIR/lib:$LD_LIBRARY_PATH" \
  PATH=$FSLDIR/share/fsl/bin:$PATH

############################################################
## Spinal Cord Toolbox (command line)
# RUN apt update && apt-get install -y curl   ## already installed for MRTrix3 
WORKDIR ${HOME}
RUN curl --location https://github.com/neuropoly/spinalcordtoolbox/archive/4.2.1.tar.gz | gunzip | tar x &&\
  cd spinalcordtoolbox-4.2.1 && (yes "y" 2>/dev/null || true) | ./install_sct && cd - && rm -rf spinalcordtoolbox-4.2.1

############################################################
## python packages in requirements.in
## before pip install fsleyes, we need to install wxPython:
WORKDIR ${HOME}
RUN .venv/bin/pip --no-cache install -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-20.04 wxpython &&\
  .venv/bin/pip install attrdict
# apt-get install freeglut3 libsdl1.2debian &&\

COPY --chown=$NB_UID:$NB_GID requirements.in ${NOTEBOOK_BASE_DIR}/requirements.in
RUN .venv/bin/pip --no-cache install pip-tools &&\
  ## rename the previously existing "requirements.txt" from the jupyter-math service (we want to keep it for user reference)
  mv ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements_base_math.txt   &&\
  .venv/bin/pip-compile --build-isolation --output-file ${NOTEBOOK_BASE_DIR}/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements.in   &&\
  .venv/bin/pip --no-cache install -r ${NOTEBOOK_BASE_DIR}/requirements.txt && \
  rm ${NOTEBOOK_BASE_DIR}/requirements.in && \
  echo "Your environment contains these python packages:" && \
  .venv/bin/pip list 

# remove write permissions from files which are not supposed to be edited
RUN chmod gu-w ${NOTEBOOK_BASE_DIR}/requirements_base_math.txt &&\
  chmod gu-w ${NOTEBOOK_BASE_DIR}/requirements.txt

## change the name of the kernel (just for display) in the kernel JSON file
ENV PYTHON_KERNEL_NAME="python (Medical Image Processing)"
ENV KERNEL_DIR ${HOME}/.local/share/jupyter/kernels/python-maths
RUN sudo apt update && sudo apt install -y jq &&\
  jq --arg a "$PYTHON_KERNEL_NAME" '.display_name = $a' ${KERNEL_DIR}/kernel.json > ${KERNEL_DIR}/temp.json \
  && mv ${KERNEL_DIR}/temp.json ${KERNEL_DIR}/kernel.json

## Modified README file, to include info about FSL
COPY --chown=$NB_UID:$NB_GID README.ipynb ${NOTEBOOK_BASE_DIR}/README.ipynb

# TEMP : for testing
COPY --chown=$NB_UID:$NB_GID Fariba_full_pipeline ${NOTEBOOK_BASE_DIR}/Fariba_full_pipeline

EXPOSE 8888

# ENTRYPOINT [ "/bin/bash" ]
ENTRYPOINT [ "/bin/bash", "/docker/entrypoint.bash" ]