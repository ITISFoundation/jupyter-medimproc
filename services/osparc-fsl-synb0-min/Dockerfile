# Headless FSL + Synb0 (Optimized)
ARG DOCKER_BASE=common/fsl_base.Dockerfile
FROM ubuntu:22.04 as runtime-base

# Setup SCU
ENV SC_USER_ID=8004
ENV SC_USER_NAME=scu
RUN useradd --uid ${SC_USER_ID} --shell /bin/sh --home /home/${SC_USER_NAME} ${SC_USER_NAME}

# Copy + Clean
COPY --from=${DOCKER_BASE} /usr/local/fsl /usr/local/fsl
RUN rm -rf /usr/local/fsl/data/standard \
    && rm -rf /usr/local/fsl/doc
# ...

COPY common/entrypoint.sh /docker/entrypoint.sh
ENTRYPOINT [ "/bin/sh", "/docker/entrypoint.sh" ]
