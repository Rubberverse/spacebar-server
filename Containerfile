ARG     IMAGE_REPOSITORY=public.ecr.aws/docker/library/node
ARG     IMAGE_VERSION=trixie-slim

# Build out the project
FROM    ${IMAGE_REPOSITORY}:${IMAGE_VERSION} AS spacebar-builder

ARG     TARGETOS
ARG     TARGETARCH
ENV     DEBIAN_FRONTEND="noninteractive"

WORKDIR /app/src
RUN apt update \
    && apt upgrade -y \
    && apt install -y \
        python-is-python3 \
        python3-pip \
        build-essential \
        git \
    && git clone https://github.com/spacebarchat/server.git . \
    && npm i \
    && npm run build \
    && npm install mediasoup-spacebar-wrtc --save \
    && npm install pg --save \
    && npm install --save sqlite3 --legacy-peer-deps

# Runner
FROM    ${IMAGE_REPOSITORY}:${IMAGE_VERSION} AS runner

ARG     CONT_UID=1001
ARG     CONT_USER=spacebar
ARG     TARGETOS
ARG     TARGETARCH

ENV     DEBIAN_FRONTEND="noninteractive" \
        PORT="3001" \
        WRTC_WS_PORT="3004" \
        DB_SYNC="false" \
        DB_LOGGING="false" \
        CONFIG_PATH="/app/configs" \
        STORAGE_PROVIDER="file" \
        STORAGE_LOCATION="/app/storage" \
        LOG_REQUESTS="-200" \
        WRTC_LIBRARY="mediasoup-spacebar-wrtc"

RUN addgroup \
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
    && mkdir -p /app/storage /app/configs

COPY    --from=spacebar-builder --chmod=0550 /app/src /app/spacebar

WORKDIR /app/spacebar
RUN chown -Rf ${CONT_USER}:${CONT_USER} /app

USER    spacebar:spacebar
VOLUME  /app/configs

ENTRYPOINT node --enable-source-maps /app/spacebar/dist/bundle/start.js
