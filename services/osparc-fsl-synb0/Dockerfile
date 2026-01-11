# Headless FSL + Synb0 (Standard)
ARG DOCKER_BASE=common/fsl_base.Dockerfile
FROM ubuntu:22.04 as runtime-base

ENV SC_USER_ID=8004
ENV SC_USER_NAME=scu
RUN useradd --uid ${SC_USER_ID} --shell /bin/sh --home /home/${SC_USER_NAME} ${SC_USER_NAME}

COPY --from=${DOCKER_BASE} /usr/local/fsl /usr/local/fsl
# ...

COPY common/entrypoint.sh /docker/entrypoint.sh
ENTRYPOINT [ "/bin/sh", "/docker/entrypoint.sh" ]
