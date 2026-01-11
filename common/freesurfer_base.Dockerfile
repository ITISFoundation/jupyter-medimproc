## Refactor as normal (ie no multistage) dockerfile
## also have a smaller base image
FROM itisfoundation/jupyter-math:2.0.9 as fs-base
LABEL maintainer="ordonez"
USER root

############################################################
## MRtrix(3)
RUN apt-get -qq update \
  && apt-get install -yq --no-install-recommends \
  curl \
  dc \
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

WORKDIR ${HOME}
RUN git clone https://github.com/MRtrix3/mrtrix3.git \
  && cd mrtrix3 && git checkout 3.0.4 \
  && ./configure && ./build -persistent -nopaginate \
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
RUN wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz | tar -xzv -C ${HOME} 
# \ && rm -rf ${HOME}/freesurfer/subjects  # we actually need subjects/fsaverage for recon-all
ENV FREESURFER_HOME ${HOME}/freesurfer
COPY freesurfer_license.txt ${FREESURFER_HOME}/license.txt
ENV FSFAST_HOME==$FREESURFER_HOME/fsfast \
  MINC_BIN_DIR=$FREESURFER_HOME/mni/bin \
  MNI_DIR=$FREESURFER_HOME/mni \
  PERL5LIB=$FREESURFER_HOME/mni/share/perl5
ENV PATH=$FREESURFER_HOME/bin:$MINC_BIN_DIR:$PATH