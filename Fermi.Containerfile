ARG     IMAGE_REPOSITORY=public.ecr.aws/docker/library/node
ARG     IMAGE_VERSION=trixie-slim

# Build out the project
FROM    ${IMAGE_REPOSITORY}:${IMAGE_VERSION} AS fermi-builder

ARG     TARGETOS
ARG     TARGETARCH
ENV     DEBIAN_FRONTEND="noninteractive"

WORKDIR /app
RUN apt update \
    && apt upgrade -y \
    && apt install -y \
        build-essential \
        git \
    && git clone https://github.com/MathMan05/Fermi.git .

COPY ./instances.json /app/src/webpage/instances.json

RUN npm i \
    && npm run build

# Runner
FROM    ${IMAGE_REPOSITORY}:${IMAGE_VERSION} AS runner

ARG     CONT_UID=1001
ARG     CONT_USER=fermi
ARG     TARGETOS
ARG     TARGETARCH

RUN apt update \
    && apt upgrade -y \
    && addgroup \
    --system \
    --gid ${CONT_UID} \
    ${CONT_USER} \
    && adduser \
        --home "/app" \
        --shell "/bin/sh" \
        --uid ${CONT_UID} \
        --ingroup ${CONT_USER} \
        --disabled-password \
        ${CONT_USER} \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/cache/* /etc/apt

COPY    --from=fermi-builder --chmod=0550 /app /app/fermi
RUN  chown -Rf ${CONT_USER}:${CONT_USER} /app

WORKDIR /app/fermi
USER    fermi:fermi

ENTRYPOINT node /app/fermi/dist/index.js
