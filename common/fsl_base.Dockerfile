## Refactor as normal (ie no multistage) dockerfile
## also have a smaller base image
FROM itisfoundation/jupyter-math:2.0.9 as fsl-base
LABEL maintainer="ordonez"
USER root

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

#############################################################################
## non-containerized Synb0-Disco
# 1: clone the github repo
WORKDIR ${HOME}
## install PyTorch for Synb0-Disco
RUN .venv/bin/pip --no-cache install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu &&\
  ## clone synb0-disco
  mkdir synb0-disco && git clone -b "master" --depth 1 https://github.com/MASILab/Synb0-DISCO ${HOME}/synb0-disco &&\
  rm -rf ${HOME}/synb0-disco/v1_0 &&\
  # save a bit of space; only 430MB and most of it is the Neural Net save files (75MB each * 5 folds)
  ### create symbolic links for other .sh files used by synb0-disco
  ln -s ${HOME}/synb0-disco/data_processing/normalize_T1.sh /usr/local/bin &&\
  ## pre-create INPUTS / OUTPUTS directories in synb0-disco; set all permissions
  mkdir synb0-disco/INPUTS &&\
  chmod gua+rwx synb0-disco/INPUTS &&\
  mkdir synb0-disco/OUTPUTS &&\
  chmod gua+rwx synb0-disco/OUTPUTS

# 2: overwrite pipeline.sh with the correct paths in our system
ENV PIPELINE_PATH=${HOME}/synb0-disco/src
COPY --chown=$NB_UID:$NB_GID pipeline_synb0_disco.sh ${PIPELINE_PATH}/pipeline_no_docker.sh

# 3: make "synb0-disco" a recognized command for the bash console
### create a symbolic link and make it executable
RUN mkdir -p /usr/local/bin && \
  ln -s -f ${PIPELINE_PATH}/pipeline_no_docker.sh /usr/local/bin &&\
  mv /usr/local/bin/pipeline_no_docker.sh /usr/local/bin/synb0-disco &&\
  chmod +x /usr/local/bin/synb0-disco && \
  ## make synb0-disco TORCH to execute in CPU (mo)
  sed -i '83s/.*/    device = torch.device("cpu")/' $HOME/synb0-disco/src/inference.py &&\
  sed -i '87s/.*/    model.load_state_dict(torch.load(model_path, map_location=torch.device("cpu")))/' $HOME/synb0-disco/src/inference.py

## install ANTS & c3d for synb0-disco
RUN curl -SL https://github.com/ANTsX/ANTs/releases/download/v2.4.4/ants-2.4.4-ubuntu-20.04-X64-gcc.zip -o ./ants-2-4-4.zip &&\
  unzip ./ants-2-4-4.zip &&\
  rm -rf ./ants-2-4-4.zip && \ 
  curl -SL https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download | tar xz
ENV PATH=$PATH:$HOME/ants-2.4.4/bin/ 
ENV ANTSPATH=$HOME/ants-2.4.4/bin/
ENV PATH=$PATH:$HOME/c3d-1.0.0-Linux-x86_64/bin/ 
