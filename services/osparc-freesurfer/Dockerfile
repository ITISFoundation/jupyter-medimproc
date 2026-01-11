# Headless FreeSurfer (Standard)
ARG DOCKER_BASE=common/freesurfer_base.Dockerfile
FROM ubuntu:22.04 as runtime-base

# Setup SCU user
ENV SC_USER_ID=8004
ENV SC_USER_NAME=scu
RUN useradd --uid ${SC_USER_ID} --shell /bin/sh --home /home/${SC_USER_NAME} ${SC_USER_NAME}

# Copy from build context (Base Image)
COPY --from=${DOCKER_BASE} /usr/local/freesurfer /usr/local/freesurfer
# ... copy other needed artifacts ...

COPY common/entrypoint.sh /docker/entrypoint.sh
ENTRYPOINT [ "/bin/sh", "/docker/entrypoint.sh" ]
