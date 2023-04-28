FROM itisfoundation/jupyter-math:2.0.8 as base
### the path (from HOME) gets writen into some files - better have access to that straighaway

############################################################
## Spinal Cord Toolbox (command line)
FROM python:3.6 as SCT_installer
WORKDIR /usr/sct
# RUN apt install gcc && apt-get update &&\
#   apt-get install -y curl sudo bzip2 xorg xterm lxterminal openssh-server &&\
#   apt-get update && apt-get install -y build-essential libgtkmm-3.0-dev libgtkglext1-dev \
#   libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev  \
#   # libwebkitgtk-3.0-dev libwebkitgtk-dev python-pip  ## not found
#   psmisc net-tools  git python3-dev  python3-pip  liblapack-dev gfortran  libjpeg-dev
RUN curl --location https://github.com/neuropoly/spinalcordtoolbox/archive/4.2.1.tar.gz | gunzip | tar x &&\
  cd spinalcordtoolbox-4.2.1 && yes | ./install_sct && cd - && rm -rf spinalcordtoolbox-4.2.1
# CMD ["./app"]  
# CMD ["/bin/bash"]

############################################################
## FSL
FROM base as fsl_installer
ENV FSLDIR ${HOME}/fsl
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
RUN echo "" | python fslinstaller.py -d ${FSLDIR}
RUN . ${FSLDIR}/etc/fslconf/fsl.sh

############################################################
## Freesurfer
FROM base as freesurfer_installer
RUN apt-get update && apt-get install -y tcsh bc libgomp1 perl-modules
ENV FREESURFER ${HOME}/freesurfer
RUN mkdir ${FREESURFER} && wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz | tar -xzv -C ${FREESURFER}
COPY freesurfer_license.txt ${FREESURFER}/freesurfer/license.txt


############################################################
## Synb0 Disco
# FROM base as synb0-disco-installer
# RUN mkdir /INPUTS && mkdir /OUTPUTS && apt-get update && apt-get -y install curl libgomp1 bc dc gcc gzip perl tcsh python3.6
# # https://ssd.mathworks.com/supportfiles/downloads/R2018a/deployment_files/R2018a/installers/glnxa64/MCR_R2018a_glnxa64_installer.zip
# RUN curl --location https://ssd.mathworks.com/supportfiles/downloads/R2018a/deployment_files/R2018a/installers/glnxa64/MCR_R2018a_glnxa64_installer.zip -o matlab_installer.zip && \
#   unzip matlab_installer.zip 
# CMD ["/bin/bash"]

############################################################
## MRtrix(3)
FROM buildpack-deps:buster as base-builder
FROM base-builder AS mrtrix3-builder
# RUN apt-get install git g++ python3 libeigen3-dev zlib1g-dev libqt5opengl5-dev libqt5svg5-dev libgl1-mesa-dev libfftw3-dev libtiff5-dev libpng-dev
RUN apt-get -qq update \
  && apt-get install -yq --no-install-recommends \
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

WORKDIR /opt/mrtrix3
RUN git clone -b "master" --depth 1 https://github.com/MRtrix3/mrtrix3.git . \
  && ./configure "" && NUMBER_OF_PROCESSORS=4 ./build -persistent -nopaginate \
  && rm -rf tmp

# Download minified ART ACPCdetect (V2.0) - needed for MRtrix(3) (?)
FROM base-builder as acpcdetect-installer
WORKDIR /opt/art
RUN curl -fsSL https://osf.io/73h5s/download \
  | tar xz --strip-components 1

# Download minified ANTs (2.3.4-2) - needed for MRtrix(3) (?)
FROM base-builder as ants-installer
WORKDIR /opt/ants
RUN curl -fsSL https://osf.io/yswa4/download \
  | tar xz --strip-components 1


#############################################################
FROM itisfoundation/jupyter-math:2.0.8 as production
LABEL maintainer="ordonez"
USER root

# Copy SpCordToolbox installation
COPY --from=SCT_installer  /root/sct_4.2.1/ ${HOME}/sct


# Copy Freesurfer installation
ENV FREESURFER_HOME ${HOME}/freesurfer
COPY --from=freesurfer_installer ${FREESURFER_HOME}/freesurfer ${FREESURFER_HOME}
# RUN apt-get update && apt-get install -y tcsh bc libgomp1 perl-modules
# # RUN mkdir ${FREESURFER_HOME} && wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz | tar -xzv -C ${FREESURFER_HOME}
# RUN wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz | tar -xzv -C ${HOME}
# ENV FREESURFER_HOME ${HOME}/freesurfer
# COPY freesurfer_license.txt ${FREESURFER_HOME}/freesurfer/license.txt
ENV FSFAST_HOME==$FREESURFER_HOME/fsfast \
  MINC_BIN_DIR=$FREESURFER_HOME/mni/bin \
  MNI_DIR=$FREESURFER_HOME/mni \
  PERL5LIB=$FREESURFER_HOME/mni/share/perl5
ENV PATH=$FREESURFER_HOME/bin:$MINC_BIN_DIR:$PATH

# Copy FSL installation
ENV FSLDIR ${HOME}/fsl
COPY --from=fsl_installer ${FSLDIR} ${FSLDIR}
# ENV FSLDIR ${HOME}/fsl
# RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
# RUN echo "" | python fslinstaller.py -d ${FSLDIR}
# RUN . ${FSLDIR}/etc/fslconf/fsl.sh
### Set all necessary FSL environment variables
ENV FSLOUTPUTTYPE="NIFTI_GZ" \
  FSLTCLSH="$FSLDIR/bin/fsltclsh" \
  FSLWISH="$FSLDIR/bin/fslwish" \
  LD_LIBRARY_PATH=$FSLDIR/fslpython/envs/fslpython/lib/ \
  LD_LIBRARY_PATH="$FSLDIR/lib:$LD_LIBRARY_PATH" \
  PATH=$FSLDIR/share/fsl/bin:$PATH
# ENV FSLGECUDAQ=cuda.q
# ENV FSL_LOAD_NIFTI_EXTENSIONS=0
# ENV FSL_SKIP_GLOBAL=0

## Synb0 Disco
## TODO

## MRtrix(3)
COPY --from=acpcdetect-installer /opt/art ${HOME}/art
COPY --from=ants-installer /opt/ants ${HOME}/ants
COPY --from=mrtrix3-builder /opt/mrtrix3 ${HOME}/mrtrix3
# Install runtime system dependencies.
RUN apt-get -qq update \
  && apt-get install -yq --no-install-recommends \
  tcsh
#   binutils \
#   dc \
#   less \
#   libfftw3-3 \
#   libgl1-mesa-glx \
#   libgomp1 \
#   liblapack3 \
#   libpng16-16 \
#   libqt5core5a \
#   libqt5gui5 \
#   libqt5network5 \
#   libqt5svg5 \
#   libqt5widgets5 \
#   libquadmath0 \
#   libtiff5 \
#   python3-distutils \
#   && rm -rf /var/lib/apt/lists/*

ENV ANTSPATH="$HOME/ants/bin" \
  ARTHOME="$HOME/art" \
  PATH="$HOME/mrtrix3/bin:$HOME/ants/bin:$HOME/art/bin:$PATH"

############################################################
## python packages in requirements.in
## before pip install fsleyes, we need to install wxPython:
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
## NAME CHANGED TEMP

## TEMP : for testing
COPY --chown=$NB_UID:$NB_GID Fariba_full_pipeline ${NOTEBOOK_BASE_DIR}/Fariba_full_pipeline
## TODO move above, whenever I will actually need to recompile
# COPY freesurfer_license.txt ${FREESURFER_HOME}/license.txt
# ENV PERL5LIB=$FREESURFER_HOME/mni/share/perl5

### It can not connect to the docker daemon
# ## Try installing docker
# RUN apt-get update && apt-get install -y ca-certificates curl gnupg

# RUN install -m 0755 -d /etc/apt/keyrings &&\
#   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&\
#   sudo chmod a+r /etc/apt/keyrings/docker.gpg

# RUN echo \
#   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#   "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# RUN sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# # RUN sudo docker run hello-world

## Reduce image size
RUN rm -rf ${FREESURFER_HOME}/subjects


## TODO move higher up at some point - adds SCT to path
ENV PATH=${HOME}/sct/bin:${PATH}

EXPOSE 8888

ENTRYPOINT [ "/bin/bash", "/docker/entrypoint.bash" ]