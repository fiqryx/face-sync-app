FROM python:3.12 AS piper-builder
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    build-essential cmake ninja-build git

WORKDIR /app
RUN git clone --depth 1 --branch v1.4.2 https://github.com/OHF-Voice/piper1-gpl.git .
RUN script/setup --dev
RUN script/dev_build
RUN script/package

FROM alpine:latest AS downloader
RUN apk add --no-cache curl jq

WORKDIR /download

ENV LOCAL=true
ENV MANIFEST_URL="https://raw.githubusercontent.com/fiqryx/face-sync/main/manifest.json"

COPY .env .
RUN sed -i 's/\r$//' .env

COPY manifest.json .
COPY build* ./build/

# Resolve {version}/{runtime}/{os} placeholders in-place so the rest of the
# script only ever deals with fully-formed URLs.
# NOTE: the jq program must stay on a single line — Dockerfile line
# continuation requires every line to end with a backslash, and a bare
# quote-only line (e.g. a lone "'") silently terminates the RUN instruction,
# causing the next line to be parsed as a new (invalid) Dockerfile directive.
RUN . ./.env && jq --arg runtime "$RUNTIME" --arg os "$OS" '.backend |= (.version as $v | .download_url |= gsub("\\{version\\}"; $v)) | .updater |= (.version as $v | .download_url |= gsub("\\{version\\}"; $v)) | .webui |= (.version as $v | .download_url |= gsub("\\{version\\}"; $v)) | .worker |= (.version as $v | .download_url |= (gsub("\\{version\\}"; $v) | gsub("\\{runtime\\}"; $runtime) | gsub("\\{os\\}"; $os)))' manifest.json > manifest.resolved.json

RUN . ./.env && \
    echo "DEBUG: LOCAL='$LOCAL' RUNTIME='$RUNTIME' OS='$OS'" && \
    echo "DEBUG: ./build contents:" && ls -la ./build/ && \
    mkdir -p backend_out worker_out updater_out webui_out && \
    FETCH_FROM_REMOTE="false" && \
    \
    if [ "$LOCAL" = "true" ]; then \
    echo "LOG: LOCAL mode is enabled. Checking local ./build/ directory..."; \
    \
    BACKEND_FILE=$(basename "$(jq -r '.backend.download_url' manifest.resolved.json)") && \
    WORKER_FILE=$(basename "$(jq -r '.worker.download_url' manifest.resolved.json)") && \
    UPDATER_FILE=$(basename "$(jq -r '.updater.download_url' manifest.resolved.json)") && \
    WEBUI_FILE=$(basename "$(jq -r '.webui.download_url' manifest.resolved.json)") && \
    echo "DEBUG: expecting BACKEND_FILE=$BACKEND_FILE WORKER_FILE=$WORKER_FILE UPDATER_FILE=$UPDATER_FILE WEBUI_FILE=$WEBUI_FILE" && \
    \
    if [ -f "./build/$BACKEND_FILE" ] && \
    [ -f "./build/$WORKER_FILE" ] && \
    [ -f "./build/$UPDATER_FILE" ] && \
    [ -f "./build/$WEBUI_FILE" ]; then \
    \
    echo "LOG: All local files found. Extracting from ./build/..." && \
    tar -xzf "./build/$BACKEND_FILE" -C ./backend_out && \
    tar -xzf "./build/$WORKER_FILE" -C ./worker_out && \
    tar -xzf "./build/$UPDATER_FILE" -C ./updater_out && \
    tar -xzf "./build/$WEBUI_FILE" -C ./webui_out; \
    else \
    echo "LOG: Some .tar.gz files are missing in ./build/. Falling back to remote download..."; \
    FETCH_FROM_REMOTE="true"; \
    fi; \
    else \
    FETCH_FROM_REMOTE="true"; \
    fi && \
    \
    if [ "$FETCH_FROM_REMOTE" = "true" ]; then \
    echo "LOG: Fetching manifest from remote URL..."; \
    curl -s "$MANIFEST_URL" > manifest.json && \
    jq --arg runtime "$RUNTIME" --arg os "$OS" '.backend |= (.version as $v | .download_url |= gsub("\\{version\\}"; $v)) | .updater |= (.version as $v | .download_url |= gsub("\\{version\\}"; $v)) | .webui |= (.version as $v | .download_url |= gsub("\\{version\\}"; $v)) | .worker |= (.version as $v | .download_url |= (gsub("\\{version\\}"; $v) | gsub("\\{runtime\\}"; $runtime) | gsub("\\{os\\}"; $os)))' manifest.json > manifest.resolved.json && \
    \
    BACKEND_URL=$(jq -r '.backend.download_url' manifest.resolved.json) && \
    WORKER_URL=$(jq -r '.worker.download_url' manifest.resolved.json) && \
    UPDATER_URL=$(jq -r '.updater.download_url' manifest.resolved.json) && \
    WEBUI_URL=$(jq -r '.webui.download_url' manifest.resolved.json) && \
    \
    curl -L "$BACKEND_URL" | tar -xz -C ./backend_out && \
    curl -L "$WORKER_URL" | tar -xz -C ./worker_out && \
    curl -L "$UPDATER_URL" | tar -xz -C ./updater_out && \
    curl -L "$WEBUI_URL" | tar -xz -C ./webui_out; \
    fi && \
    \
    # Cleanup local build directory to keep image size small
    rm -rf ./build

FROM python:3.12-slim
WORKDIR /app

ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    supervisor \
    curl \
    libgomp1 \
    sed \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY --from=piper-builder /app/dist/piper_tts-*linux*.whl ./dist/
RUN pip3 install ./dist/piper_tts-*linux*.whl flask && rm -rf ./dist

COPY .env .
COPY ./version.json ./version.json

COPY --from=downloader /download/backend_out/ .
COPY --from=downloader /download/worker_out/ .
COPY --from=downloader /download/updater_out/ .
COPY --from=downloader /download/webui_out/ ./webui

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh .

RUN chmod +x backend
RUN chmod +x updater
RUN chmod +x main.bin
RUN sed -i 's/\r$//' entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 8000 3000

ENTRYPOINT ["./entrypoint.sh"]