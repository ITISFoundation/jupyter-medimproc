# Headless FreeSurfer (Optimized)
ARG DOCKER_BASE=common/freesurfer_base.Dockerfile
FROM ubuntu:22.04 as runtime-base

# Setup SCU
ENV SC_USER_ID=8004 \
    SC_USER_NAME=scu
RUN useradd --uid ${SC_USER_ID} --shell /bin/sh --home /home/${SC_USER_NAME} ${SC_USER_NAME}

# Copy + Clean (Optimization logic)
COPY --from=${DOCKER_BASE} /usr/local/freesurfer /usr/local/freesurfer
RUN rm -rf /usr/local/freesurfer/subjects \
    && rm -rf /usr/local/freesurfer/docs \
    && rm -rf /usr/local/freesurfer/trctrain
# ...

COPY common/entrypoint.sh /docker/entrypoint.sh
ENTRYPOINT [ "/bin/sh", "/docker/entrypoint.sh" ]
